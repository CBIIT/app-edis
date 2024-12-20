'use strict'

const {conf} = require("./conf");
const ldap = require('ldapjs');
const {convertBase64Fields, getProvidedEmail, getDOC} = require("./util");
const {AndFilter, EqualityFilter, PresenceFilter} = require("ldapjs/lib/filters");

let tlsOptions;

function vdsRoutes(app, opts) {

    app.get('/userById/:id', async (req, res) => {
        console.info('/userapi/vds/userById', req.params);
        try {
            const id = req.params.id;
            if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                res.json({ 'Success': true});
            }
            else
            {
                res.json(await getUsersEnhanced(id, '*'));
            }
        } catch (error) {
            console.error(error);
            res.status(500).send(error);
        }
    });
    app.get('/usersByIc/:ic', async (req, res) => {
        console.info('/userapi/vds/usersByIc', req.params);
        try {
            const ic = req.params.ic;

            if (ic === undefined) {
                res.status(400).send('IC is not defined.');
            }
            else if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                res.json({ 'Success': true});
            }
            else {
                res.json(await getUsersEnhanced(null, ic));
            }
        } catch (error) {
            res.status(500).send(error);
        }
    });
}

const getUsersEnhanced = async (userId, ic) => {

    console.debug('Starting and waiting for getUsers from VDS...');
    const users = await getUsers(userId, ic, conf.vds, conf.vds.NIHInternalView, false);
    const counter = users.length;
    console.debug("getUsers from VDS ...done. Records retrieved", counter );

    console.debug('Starting and waiting for getUsers from nVision VDS ...')
    const userMap = await getUsers(userId, ic, conf.vds, conf.vds.nvision, true);
    const mapSize = userMap.size;
    console.debug("getUsers from nVision VDS ...done. Records retrieved", mapSize );

    enhanceUserList(users, userMap);
    return users;
};


const getUsers = async (userId, ic, credentials, config, isMap) => {

    return new Promise(async function (resolve, reject) {

        console.info('getUsers()', userId, ic);
        let icSubFilter = null;
        if (ic) {
            if (ic === '*') {
                icSubFilter = new PresenceFilter({
                    attribute: config.icAttribute
                });
            }
            else {
                icSubFilter = new EqualityFilter({
                    attribute: config.icAttribute,
                    value: ic
                });
            }
        }
        let userIdFilter = null;
        if (userId) {
            if (userId === '*') {
                userIdFilter = new PresenceFilter({
                    attribute: config.primaryAttribute
                });
            } else {
                userIdFilter = new EqualityFilter({
                    attribute: config.primaryAttribute,
                    value: userId
                });
            }
        }

        const filter = (userIdFilter && icSubFilter) ? new AndFilter({
            filters: [ userIdFilter, icSubFilter ]
            }) :
            (icSubFilter ? icSubFilter : userIdFilter);
        console.debug('created filter', filter.toString());

        const userSearchOptions = {
            scope: 'sub',
            attributes: config.userAttributes,
            filter: filter,
            paged: true
        };

        const ldapClient = await getLdapClient(credentials);

        ldapClient.bind(credentials.dn, credentials.pwd, function (err) {

            if (err) {
                console.error('Ldap client bind error: ' + err);
                ldapClient.destroy();
                return reject(Error(err.message));
            }
            let userList = [];
            let userMap = new Map();
            let counter = 0;
            console.info('starting search', config.searchBase);
            ldapClient.search(config.searchBase, userSearchOptions, function (err, ldapRes) {
                if (err) {
                    console.error('Ldap client search error', err);
                    return reject(Error(err.message));
                }
                if (!ldapRes) {
                    const message = 'Ldap client search result event error';
                    console.error(message);
                    return reject(message);
                }
                ldapRes.on('searchEntry', function (entry) {
                    if (++counter % 10000 === 0) {
                        console.info(counter + ' records found and counting...');
                    }
                    let obj = convertBase64Fields(entry, config.base64LdapFields);
                    if (isMap) {
                        let key = obj[config.primaryAttribute];
                        delete obj[config.primaryAttribute];
                        userMap.set(key, obj);
                    }
                    else {
                        userList.push(obj);
                    }
                });
                ldapRes.on('searchReference', function () { });
                ldapRes.on('page', function () {
                    console.info(`page end | ${counter} users fetched`);
                });
                ldapRes.on('error', function (err) {
                    ldapClient.destroy();
                    if (err.code === 32) {
                        // Object doesn't exist. The user DN is most likely not fully provisioned yet.
                        resolve({});
                    } else {
                        console.error('ldap err', err);
                        reject(Error(err.message));
                    }
                });
                ldapRes.on('end', function () {
                    console.info('ldap end - destroy client');
                    ldapClient.destroy();
                    console.info('ldap end...done', counter);
                    resolve(isMap ? userMap : userList);
                });
            });
        });
    });
};

const getLdapClient = async (credentials) => {

    try {
        const ldapClient = await ldap.createClient({
            url: credentials.host,
            tlsOptions: _getTlsOptions(credentials),
            idleTimeout: 15 * 60 * 1000,
            timeout: 15 * 60 * 1000,
            connectTimeout: 15 * 60 * 1000 // 15 mins
        });

        ldapClient.on('connectError', function (err) {
            console.error('ldap client connectError: ' + err);
        });

        ldapClient.on('error', function (err) {
            console.error('ldap client error: ' + err);
        });

        ldapClient.on('resultError', function (err) {
            console.error('ldap client resultError: ' + err);
        });

        ldapClient.on('socketTimeout', function (err) {
            console.error('ldap socket timeout: ' + err);
        });

        ldapClient.on('timeout', function (err) {
            console.error('ldap client timeout: ' + err);
        });
        return ldapClient;
    } catch (error) {
        return Error(error);
    }
};


function _getTlsOptions(credentials) {
    if (!tlsOptions) {
        // console.log('cert', conf.vds.cert)
        tlsOptions = {
            ca: [credentials.cert]
        };
    }
    return tlsOptions;
}

function enhanceUserList(userList, userMap) {
    for (let obj of userList) {
        obj['providedEmail'] = getProvidedEmail(obj);
        obj['DOC'] = getDOC(obj);

        // Enhance user record from userMap
        let additionalObj = userMap.get(obj['UNIQUEIDENTIFIER']);
        if (additionalObj) {
            for (let prop in additionalObj) {
                obj[prop] = additionalObj[prop];
            }
        }
    }
}

module.exports = {vdsRoutes, getUsersEnhanced};