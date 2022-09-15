'use strict'

const {conf} = require("./conf");
const ldap = require('ldapjs');
const {convertBase64Fields, sleep, getProvidedEmail} = require("./util")
const {AndFilter, EqualityFilter, SubstringFilter, NotFilter, OrFilter} = require("ldapjs/lib/filters");

let tlsOptions;
/**
 * 
 * @param ic - NIHORGACRONYM to include
 * @param divisions - list of strings NIHORGACRONYM starts with - to include / exclude 
 * @param includeDivs - true to include divisions, false to exclude divisions if any 
 * @param pageCallBack
 * @param s3Entry
 * @returns {Promise<unknown>}
 */
const getUsers = async (ic, divisions, includeDivs, pageCallBack, s3Entry) => {

    return new Promise(async function (resolve, reject) {

        const userSearchOptions = {
            scope: 'one',
            // attributes: conf.vds.user_attributes,
            paged: true,
            sizeLimit: 501
        };
        if (conf.vds.includedAttributes && conf.vds.includedAttributes.length > 0) {
            userSearchOptions.attributes = conf.vds.includedAttributes;
        }
        if (ic && ic.length > 0) {
            let filter = new EqualityFilter({
                attribute: 'NIHORGACRONYM',
                value: ic
            });

            if (divisions && divisions.length === 1) {
                const divFilter = new SubstringFilter({
                    attribute: 'NIHORGPATH',
                    initial: divisions[0]
                });
                filter = new AndFilter({
                    filters: [
                        filter,
                        includeDivs ? divFilter : new NotFilter({ filter: divFilter })
                    ] 
                })
            }
            else if (divisions && divisions.length > 1) {
                const divFilters = [];
                for (const division of divisions) {
                    const divFilter = new SubstringFilter({
                        attribute: 'NIHORGPATH',
                        initial: division
                    });
                    divFilters.push(divFilter); 
                }
                const divFilter = new OrFilter({
                    filters: divFilters
                })
                
                filter = new AndFilter({
                    filters: [
                        filter,
                        includeDivs ? divFilter : new NotFilter({ filter: divFilter })
                    ]
                });
            }
            console.debug('created filter', filter);
            userSearchOptions.filter = filter;
        }

        console.debug('User Search Options', userSearchOptions);
        
        const ldapClient = await getLdapClient();

        ldapClient.bind(conf.vds.dn, conf.vds.pwd, function (err) {

            if (err) {
                console.error('Ldap client bind error' + err);
                ldapClient.destroy();
                return reject(Error(err.message));
            }
            let users = [];
            let counter = 0;
            let chunk = [];
            let processingPage = false; 
            console.info('starting search');
            ldapClient.search(conf.vds.searchBase, userSearchOptions, function (err, ldapRes) {
                if (err) {
                    console.error('Ldap client search error',err);
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
                    let obj = convertBase64Fields(entry);
                    obj['providedEmail'] = getProvidedEmail(obj);
                    users.push(obj);
                });
                ldapRes.on('searchReference', function (reference) {
                    console.debug('ldap searchReference - ', reference);
                });
                ldapRes.on('page', async function () {
                    processingPage = true;
                    console.info('ldap page - records fetched', counter);
                    if (pageCallBack) {
                        await waitForChunkEmpty(chunk);
                        chunk = [];
                        users.forEach(user => chunk.push(user));
                        users = [];
                        await pageCallBack(chunk, counter, s3Entry);
                    }
                    console.debug('ldap page...done - record fetched', counter);
                    processingPage = false;
                });
                ldapRes.on('error', function (err) {
                    console.error('ldap error - records fetched', counter, err);
                    ldapClient.destroy();
                    if (err.code === 32) {
                        // Object doesn't exist. The user DN is most likely not fully provisioned yet.
                        resolve(counter);
                    } else {
                        console.error('ldap error', err);
                        reject(Error(err.message));
                    }
                });
                ldapRes.on('end', async function () {
                    console.info('ldap end - destroy client');
                    while (processingPage) {
                        await waitForChunkEmpty(chunk);
                    }
                    ldapClient.destroy();
                    console.info('ldap end...done', counter);
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
            connectTimeout: 15 * 60 * 1000 // 15 minutes
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
            console.error('ldap client socket timeout: ' + err);
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
        tlsOptions = {
            ca: [conf.vds.cert]
        };
    }
    return tlsOptions;
}

async function waitForChunkEmpty(chunk) {
    console.debug('Wait for chunk empty', chunk.length);
    while (chunk.length > 0) {
        await sleep(1000);
    }
    console.debug('Wait for chunk empty...done', chunk.length);
}

module.exports = {getUsers}
