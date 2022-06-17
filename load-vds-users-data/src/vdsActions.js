'use strict'

const {conf} = require("./conf");
const ldap = require('ldapjs');
const {convertBase64Fields} = require("./util")

let tlsOptions;

const getUsers = async (ic, pageCallBack) => {

    return new Promise(async function (resolve, reject) {

        const filter = '(NIHORGACRONYM=' + ic + ')';

        var userSearchOptions = {
            scope: 'sub',
            // attributes: conf.vds.user_attributes,
            // filter: filter,
            paged: true
        };
        const ldapClient = await getLdapClient();

        ldapClient.bind(conf.vds.dn, conf.vds.pwd, function (err) {

            if (err) {
                console.error('Bind error: ' + err);
                ldapClient.destroy();
                return reject(Error(err.message));
            }
            let users = [];
            let counter = 0;
            console.info('starting search');
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
                ldapRes.on('page', async function () {
                    console.info(`page end | ${counter} users fetched`);
                    if (pageCallBack) {
                        const chunk = [];
                        users.forEach(user => chunk.push(user));
                        users = [];
                        await pageCallBack(chunk, counter);
                    }
                });
                ldapRes.on('error', function (err) {
                    ldapClient.destroy();
                    if (err.code === 32) {
                        // Object doesn't exist. The user DN is most likely not fully provisioned yet.
                        resolve(counter);
                    } else {
                        console.error('err');
                        reject(Error(err.message));
                    }
                });
                ldapRes.on('end', function () {
                    console.info('destroy client');
                    console.info(counter + ' records found');
                    ldapClient.destroy();
                    resolve(counter);
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

module.exports = {getUsers}