'use strict'

const AWSXRay = require('aws-xray-sdk-core')
const {conf} = require("./conf");
const ldap = require('ldapjs');
const {convertBase64Fields} = require("./util")

const AWS = AWSXRay.captureAWS(require('aws-sdk'))
AWS.config.update({ region: "us-east-1"});

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
                res.json(await getUsers(id, '*'));
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
                res.json(await getUsers(null, ic));
            }
        } catch (error) {
            res.status(500).send(error);
        }
    });
}

const getUsers = async (userId, ic) => {

    return new Promise(async function (resolve, reject) {

        const nciSubFilter = '(NIHORGACRONYM=' + ic + ')';
        const filter = userId ? ('(&(UNIQUEIDENTIFIER=' + userId + ')' + nciSubFilter + ')') : nciSubFilter;
        console.info('getUsers()', userId, ic, nciSubFilter, filter);
        var userSearchOptions = {
            scope: 'sub',
            attributes: conf.vds.userAttributes,
            filter: filter,
            paged: true
        };
        var counter = 0;
        const ldapClient = await getLdapClient();

        ldapClient.bind(conf.vds.dn, conf.vds.pwd, function (err) {

            if (err) {
                console.error('Bind error: ' + err);
                ldapClient.destroy();
                return reject(Error(err.message));
            }
            var users = [];
            console.info('starting search', filter);
            ldapClient.search(conf.vds.searchBase, userSearchOptions, function (err, ldapRes) {
                if (err) {
                    console.error(err);
                    return reject(Error(err.message));
                }
                if (!ldapRes) {
                    const message = 'Could not get LDAP result!';
                    console.error(message);
                    return reject(message);
                }
                ldapRes.on('searchEntry', function (entry) {
                    if (++counter % 10000 === 0) {
                        console.info(counter + ' records found and counting...');
                    }
                    let obj = convertBase64Fields(entry);
                    users.push(obj);
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
                        console.error('err');
                        reject(Error(err.message));
                    }
                });
                ldapRes.on('end', function () {
                    console.info('destroy client');
                    console.info(counter + ' records found');
                    ldapClient.destroy();
                    resolve(users);
                });
            });

        });

    });
};

const getLdapClient = async () => {

    try {
        const ldapClient = await ldap.createClient({
            url: conf.vds.host,
            tlsOptions: _getTlsOptions(),
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


function _getTlsOptions() {
    if (!tlsOptions) {
        // console.log('cert', conf.vds.cert)
        tlsOptions = {
            ca: [conf.vds.cert]
        };
    }
    return tlsOptions;
}

module.exports = {vdsRoutes, getUsers}