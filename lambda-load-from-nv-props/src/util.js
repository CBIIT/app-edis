'use strict'

function convertForDynamoDB(row) {
    const res = {}
    for (const p in row) {
        const newProp = p; //TODO -- add if you need to map to a new property
        if (row[p] == null) {
            res[newProp] = null;
        }
        else if (typeof(row[p]) === 'number') {
            res[newProp] = row[p];
        }
        else if (row[p] instanceof Date) {
            res[newProp] = formatDate(row[p]);
        } else {
            res[newProp] = cleanString(row[p]);
        }
    }
    if (res['ASSET_KEY'] === undefined) {
        res['ASSET_KEY'] = 'UNKNOWN';
    }
    else {
        res['ASSET_KEY'] = '' + res['ASSET_KEY']; // convert to string
    }
    return res;
}

// add leading zero
function padTo2Digits(num) {
    return num.toString().padStart(2, '0');
}

function formatDate(date) {
    return date.toISOString();
}

function cleanString(str) {
    if (str.indexOf('\t') >= 0) {
        console.log('string with tab: ', str )
    }
    let ret = str.replace(/"/g, '\\"');
    return ret.replace(/\u0009/g, "");
}


function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = { convertForDynamoDB, sleep };