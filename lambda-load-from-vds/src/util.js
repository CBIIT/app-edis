'use strict'

/** Converts specific fields in an LDAP result entry to  to base64.
 * @input entry
 */
function convertBase64Fields(entry, base64LdapFields) {
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

// add leading zero
function padTo2Digits(num) {
    return num.toString().padStart(2, '0');
}

function formatDate(date) {
    return (
        [
            date.getFullYear(),
            padTo2Digits(date.getMonth() + 1),
            padTo2Digits(date.getDate()),
            padTo2Digits(date.getHours()),
            padTo2Digits(date.getMinutes()),
            padTo2Digits(date.getSeconds()),
        ].join('')
    );
}

function getEmail(obj) {

    let result = null;

    const proxyEmails = obj.proxyAddresses;
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
    return result;
}

function getProvidedEmail(entry) {
    let result = getEmail(entry);

    if (result == null) result = entry.MAIL;
    if (result == null) return entry.NIHPRIMARYSMTP;
    return result;
}

function getBuilding(obj) {

    if (obj.BUILDINGNAME) {
        return 'BG ' + obj.BUILDINGNAME;
    } else {
        return 'N/A';
    }
}

function getDivision(obj) {

    let result = 'N/A';

    if (obj.NIHORGPATH) {
        const orgPathArr = obj.NIHORGPATH.split(' ') || [];
        const len = orgPathArr.length;

        if (len > 0 && len <= 2) {
            result = orgPathArr[len - 1];
        } else if (len > 2) {
            if (orgPathArr[1] === 'OD') {
                result = orgPathArr[2];
            } else {
                result = orgPathArr[1];
            }
        }
    }

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

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = { convertBase64Fields, padTo2Digits, formatDate, getEmail, getProvidedEmail, getBuilding, getDivision, getDOC, sleep };