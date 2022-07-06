'use strict'

require('console-stamp')(console);

const AWS = require('aws-sdk'),
    region = 'us-east-1'
const {AthenaExpress} = require("athena-express");

AWS.config.update({ region: region });

const athenaExpressConfig = {
    aws: AWS,
    s3: 's3://cf-templates-woyzwinjenjf-us-east-1/app-edis-data-dev2/delta/',
    db: 'vdsdb1_db',
    getStats: true,
    skipResults: true
}; //configuring athena-express with aws sdk object

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel === 'info') {
    console.debug = function () {}
}

module.exports.handler = async (event, context) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.debug('Lambda-athena-vds-user-delta', event);
    
    try {
        const athenaExpress = new AthenaExpress(athenaExpressConfig);
        let query = 'select content from (\n' +
            'select id, content from "currentp_t"\n' +
            'except\n' +
            'select id, content from "prevp_t")';
        const deltaResults = await athenaExpress.query(query);
        console.info('New and changed delta:', deltaResults);
        
        query = 'select id from "prevp_t"\n' +
            'except\n' +
            'select id from "currentp_t")';
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
