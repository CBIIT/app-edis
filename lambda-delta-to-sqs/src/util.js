'use strict'

// add leading zero
function padTo2Digits(num) {
    return num.toString().padStart(2, '0');
}

/**
 * Format a refresh timestamp as "YYYYMMddHHmmss"
 * @param date  Date object
 * @returns {string} formatted string
 */
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

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = { formatDate, sleep };