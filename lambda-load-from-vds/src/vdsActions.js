'use strict'

const {conf} = require('./conf');
const ldap = require('ldapjs');
const {convertBase64Fields, getProvidedEmail, getDivision, getEmail, getBuilding, getDOC} = require("./util");
const {AndFilter, EqualityFilter, SubstringFilter, NotFilter, OrFilter} = require("ldapjs/lib/filters");

let tlsOptions;

/**
 * @param ic - NIH IC to include
 * @param divisions - list of strings NIH Org path starts with - to include / exclude
 * @param includeDivs - true to include divisions, false to exclude divisions if any
 * @returns {Promise<unknown>}
 */
const getUsersEnhanced = async (ic, divisions, includeDivisions) => {

    console.debug('Starting and waiting for getUsers from VDS...')
    const users = await getUsers(ic, divisions, includeDivisions, conf.vds, conf.vds.NIHInternalView, false);
    const counter = users.length;
    console.debug("getUsers from VDS ...done. Records retrieved", counter );

    console.debug('Starting and waiting for getUsers from nVision VDS ...')
    const userMap = await getUsers(ic, divisions, includeDivisions, conf.vds, conf.vds.nvision, true);
    const mapSize = userMap.size;
    console.debug("getUsers from nVision VDS ...done. Records retrieved", mapSize );

    enhanceUserList(users, userMap);
    return users;
}

/**
 * 
 * @param ic - NIH IC to include
 * @param divisions - list of strings NIH Org path starts with - to include / exclude
 * @param includeDivs - true to include divisions, false to exclude divisions if any
 * @param credentials - credentials section from conf.js
 * @param config - configuration section from conf.js
 * @param isMap - true if the returned class is Map (otherwise - array)
 * @returns {Promise<unknown>}
 */
const getUsers = async (ic, divisions, includeDivs, credentials, config, isMap) => {

    return new Promise(async function (resolve, reject) {

        const userSearchOptions = {
            scope: 'one',
            // attributes: conf.vds.user_attributes,
            paged: true,
            sizeLimit: 501
        };
        if (config.includedAttributes && config.includedAttributes.length > 0) {
            userSearchOptions.attributes = config.includedAttributes;
        }
        if (ic && ic.length > 0) {
            let filter = new EqualityFilter({
                attribute: config.icAttribute,
                value: ic
            });

            if (divisions && divisions.length === 1) {
                const divFilter = new SubstringFilter({
                    attribute: config.orgpathAttribute,
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
                        attribute: config.orgpathAttribute,
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
        
        const ldapClient = await getLdapClient(credentials);

        ldapClient.bind(credentials.dn, credentials.pwd, function (err) {

            if (err) {
                console.error('Ldap client bind error' + err);
                ldapClient.destroy();
                return reject(Error(err.message));
            }
            let userList = [];
            let userMap = new Map();
            let counter = 0;
            console.info('starting search');
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

                    // Remove excluded fields
                    for (const attr of config.excludedAttributes) {
                        delete obj[attr];
                    }
                    if (isMap) {
                        let key = obj[config.primaryAttribute];
                        delete obj[config.primaryAttribute];
                        userMap.set(key, obj);
                    }
                    else {
                        userList.push(obj);
                    }
                });
                ldapRes.on('searchReference', function (reference) {
                    console.debug('ldap searchReference - ', reference);
                });
                ldapRes.on('page', async function () {
                    console.debug('ldap page - records fetched', counter);
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

function _getTlsOptions(credentials) {
    if (!tlsOptions) {
        tlsOptions = {
            ca: [credentials.cert]
        };
    }
    return tlsOptions;
}

function enhanceUserList(userList, userMap) {
    for (let obj of userList) {
        // Enhance user record with additional fields
        obj['NEDId'] = '' + obj.UNIQUEIDENTIFIER;
        obj['FirstName'] = obj.GIVENNAME;
        obj['MiddleName'] = obj.MIDDLENAME;
        obj['LastName'] = obj.NIHMIXCASESN;
        obj['Email'] = getEmail(obj);
        obj['Phone'] = obj.TELEPHONENUMBER;
        obj['Classification'] = obj.ORGANIZATIONALSTAT;
        obj['SAC'] = obj.NIHSAC;
        obj['AdministrativeOfficerId'] = obj.NIHSERVAO;
        obj['COTRId'] = obj.NIHCOTRID;
        obj['ManagerId'] = obj.MANAGER;
        obj['Locality'] = obj.L;
        obj['PointOfContactId'] = obj.NIHPOC;
        obj['Division'] = getDivision(obj);
        obj['Locality'] = obj.L;
        obj['Site'] = obj.NIHSITE;
        obj['Building'] = getBuilding(obj);
        obj['Room'] = obj.ROOMNUMBER;
        obj['providedEmail'] = getProvidedEmail(obj);
        obj['DOC'] = getDOC(obj);

        // Enhance user record from userMap
        let additionalObj = userMap.get(obj['NEDId']);
        if (additionalObj) {
            for (let prop in additionalObj) {
                obj[prop] = additionalObj[prop];
            }
        }
    }
}

module.exports = { getUsersEnhanced }
