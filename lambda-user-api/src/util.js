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

}

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
    if (result == null) result = entry.MAIL;
    if (result == null) return entry.NIHPRIMARYSMTP;
    return result;
}

function getDOC(obj) {
    let result = '';
    if (obj && obj.NIHSAC && obj.NIHORGPATH && obj.NIHSAC.startsWith('HNC')) {
        result = 'NCI'; // org[0]

        //First, figure out the separator
        const sep = (obj.NIHORGPATH.indexOf('/') > 0) ? '/' : ' ';

        const orgs = obj.NIHORGPATH.split(sep);
        if (orgs.length > 1) {
            result += sep + orgs[1];
        }
        if ((obj.NIHSAC.length > 3) && (obj.NIHSAC.charAt(3) === '1')) {
            if (orgs.length > 2) {
                result += sep + orgs[2];
            }
            if ((obj.NIHSAC.length > 4) && (obj.NIHSAC.charAt(4) === '7')) {
                if (orgs.length > 3) {
                    result += sep + orgs[3];
                }
            }
        }
    }
    return result;
}


module.exports = { convertBase64Fields, getProvidedEmail, getDOC };