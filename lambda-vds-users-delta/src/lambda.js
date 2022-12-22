'use strict'

require('console-stamp')(console);

const AWS = require('aws-sdk'),
    region = 'us-east-1'
const {AthenaExpress} = require("athena-express");

AWS.config.update({ region: region });

// Environment variables
const logLevel = process.env['LOG_LEVEL'];
const s3bucket = process.env['S3BUCKET'];
const s3folder = process.env['S3FOLDER'];
const db       = process.env['DB_NAME'];
let current_t  = process.env['DB_CURRENT_T'] || 'currentp_t';
let prev_t     = process.env['DB_PREV_T']    || 'prevp_t';

const athenaExpressConfig = {
    aws: AWS,
    s3: 's3://' + s3bucket + '/' + s3folder + '/delta/',
    db: db,
    getStats: true,
    skipResults: true
}; //configuring athena-express with aws sdk object

// Set the console log level
if (logLevel && logLevel === 'info') {
    console.debug = function () {}
}

module.exports.handler = async (event, context) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.debug('Lambda-athena-vds-user-delta', event);
    
    //Overwrite athena express configuration from event values (optional)
    if (event['DB_NAME'] !== undefined) {
        athenaExpressConfig.db = event['DB_NAME'];
    }
    if (event['S3SUBFOLDER'] !== undefined) {
        athenaExpressConfig.s3 = 's3://' + s3bucket + '/' + s3folder + '/' +  event['S3SUBFOLDER'] + '/delta/';
    }
    if (event['DB_CURRENT_T'] !== undefined) {
        current_t = event['DB_CURRENT_T'];
    }
    if (event['DB_PREV_T'] !== undefined) {
        prev_t = event['DB_PREV_T'];
    }
    
    try {
        const athenaExpress = new AthenaExpress(athenaExpressConfig);
        let query = 'select content from (\n' +
            'select id, content from "' + current_t + '"\n' +
            'except\n' +
            'select id, content from "' + prev_t + '")';
        const deltaResults = await athenaExpress.query(query);
        console.info('New and changed delta:', deltaResults);
        
        query = 'select id from "' + prev_t + '"\n' +
            'except\n' +
            'select id from "' + current_t + '"';
        const deletedResults = await athenaExpress.query(query);
        console.info('Deleted delta:', deletedResults);

        return {
            delta: deltaResults.S3Location,
            deleted: deletedResults.S3Location
        };

    } catch (error) {
        console.error('Lambda-athena-vds-user-delta failed', error);
        throw error;
    }
}
