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
function formatTimestamp(date) {
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

/**
 * Format a refresh date as "YYYY-MM-dd"
 * @param date  Date object
 * @returns {string} formatted string
 */
function formatDay(date) {
    return (
        [
            date.getFullYear(),
            '-',
            padTo2Digits(date.getMonth() + 1),
            '-',
            padTo2Digits(date.getDate())
        ].join('')
    );
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = { formatTimestamp, formatDay, sleep };