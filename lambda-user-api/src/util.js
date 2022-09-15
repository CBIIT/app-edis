'use strict'

const { conf } = require('./conf');
const base64LdapFields = conf.vds.base64LdapFields;


/** Converts specific fields in an LDAP result entry to  to base64.
 * @input entry
 */
function convertBase64Fields(entry) {
    let obj = entry.object;
    const raw = entry.raw;

    base64LdapFields.forEach( field => {
        let base64Field = raw[field];
        if (base64Field) {
            obj[field] = base64Field.toString('base64');
        }
    });

    return obj;

};

function getProvidedEmail(entry) {
    let result = null;

    const proxyEmails = entry.proxyAddresses;
    if (proxyEmails) {
        if (Array.isArray(proxyEmails)) {
            proxyEmails.forEach(email => {
                const data = email.split(':');
                if (data[0] === 'SMTP') {
                    result = data[1];
                }
            });
        } else {
            const data = proxyEmails.split(':');
            if (data[0] === 'SMTP') {
                result = data[1];
            }
        }
    }
    if (result == null) result = obj.MAIL;
    if (result == null) return obj.NIHPRIMARYSMTP;
    return result;
}

module.exports = { convertBase64Fields, getProvidedEmail };