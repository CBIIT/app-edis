'use strict'

// const { formatDate } = require("./util");

const AWS = require('aws-sdk'),
    region = 'us-east-1'

AWS.config.update({ region: region });


// Environment variables
const logLevel = process.env['LOG_LEVEL'];
const bucket   = process.env['S3BUCKET'];
const folder   = process.env['S3FOLDER'];

// Set the console log level
if (logLevel && logLevel === 'info') {
    console.debug = function () {}
}

const S3 = new AWS.S3();

module.exports.handler = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.info('Lambda-prepare-s3-for-vds', event);
    
    // const marker = formatDate(new Date());
    
    try {
        console.debug('Checking the prev folder of S3...')
        const params = {
            Bucket: bucket,
            Prefix: folder + '/prev/'
        }
        const listedFiles = await S3.listObjectsV2(params).promise();
        if (listedFiles && listedFiles.Contents.length > 0) {
            const deleteParams = {
                Bucket: bucket,
                Delete: { Objects: [] }
            };
            listedFiles.Contents.forEach((content) => {
                deleteParams.Delete.Objects.push({ Key: content.key});
            });
            console.info('Clean up files from prev folder', deleteParams);
        }
        callback(null, {
            ICList: [ 'OD', 'NCI']
        });
    } catch (error) {
        console.error('lambda handler',error);
        throw error;
    }
}

