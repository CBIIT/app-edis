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
    console.debug('Lambda-cds-user-delta', event);
    
    try {
        const athenaExpress = new AthenaExpress(athenaExpressConfig);
        let deltaQuery = 'select content from (\n' +
            'select id, content from "currentp_t"\n' +
            'except\n' +
            'select id, content from "prevp_t")';
        let results = await athenaExpress.query(deltaQuery);
        console.info('Delta has been created', results);
        return results.S3Location;
    } catch (error) {
        console.error(error);
        throw error;
    }
}
