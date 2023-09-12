'use strict';

const ldap = require('ldapjs-promise');
const { conf } = require("./conf");

const authLdap = async (dn, pwd) => {
    return new Promise(async function(resolve, reject) {
        try {
            console.debug('get Ldap Client...');
            const ldapClient = getLdapClient();
            console.debug('bind Ldap Client...');
            await ldapClient.bind(dn, pwd);
            console.debug('unbind Ldap Client...');
            await ldapClient.unbind();
            console.debug('Auth Ldap is completed');
            return resolve(true);
        } catch (e) {
            console.error(e);
            return reject(e.message);
        }
    })
};

const getLdapClient = () => {
    console.debug('host:', conf.ad.host);
    console.debug('cert:', conf.ad.cert);
    const ldapClient = ldap.createClient({
        url: conf.ad.host,
        tlsOptions: {
            ca: [conf.ad.cert]
        },
        idleTimeout: 15 * 60 * 1000,
        timeout: 15 * 60 * 1000,
        connectTimeout: 15 * 60 * 1000 // 15 minutes
    });

    ldapClient.on('connectError', function (err) {
        console.error('ldap client connectError: ', err);
    });

    ldapClient.on('error', function (err) {
        console.error('ldap client error: ', err);
    });

    ldapClient.on('resultError', function (err) {
        console.error('ldap client resultError: ', err);
    });

    ldapClient.on('socketTimeout', function (err) {
        console.error('ldap client socket timeout: ', err);
    });

    ldapClient.on('timeout', function (err) {
        console.error('ldap client timeout: ', err);
    });
    return ldapClient;
};

module.exports = {authLdap};