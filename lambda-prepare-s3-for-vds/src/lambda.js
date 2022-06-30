'use strict'
const { conf } = require('./conf');
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
        // Step1.  Remove all files from .../prev/ folder
        console.debug('Removing all files from prev folder of S3...')
        const prevPrefix = folder + '/prev/';
        const currPrefix = folder + '/current/'
        const prevParams = {
            Bucket: bucket,
            Prefix: prevPrefix
        }
        const deleteParams = {
            Bucket: bucket,
            Delete: { Objects: [] }
        };

        let listedFiles = await S3.listObjectsV2(prevParams).promise();
        console.debug('Preparing list of objects to delete...', listedFiles.Contents.length);
        if (listedFiles && listedFiles.Contents.length > 0) {
            listedFiles.Contents.forEach((content) => {
                deleteParams.Delete.Objects.push({ Key: content.Key});
                console.debug('Clean up file', content.Key);
            });
            console.info('Prepare to cleanup...done', deleteParams.Delete.Objects.length, 'objects')
            console.debug('About to delete...', deleteParams)
            const deletedResponse = await S3.deleteObjects(deleteParams).promise();
            console.debug('Delete objects...done', deletedResponse.Deleted);
        }

        // Step2.  Move all files from .../current/ folder
        const currParams = {
            Bucket: bucket,
            Prefix: currPrefix
        }
        listedFiles = await S3.listObjectsV2(currParams).promise();
        console.debug('Preparing list of objects to move...', listedFiles.Contents.length);
        if (listedFiles && listedFiles.Contents.length > 0) {
            deleteParams.Delete.Objects = [];
            await Promise.all(
                listedFiles.Contents.map(async (fileInfo) => {
                    deleteParams.Delete.Objects.push({Key: fileInfo.Key});
                    await S3.copyObject({
                        Bucket: bucket,
                        CopySource: bucket + '/' + fileInfo.Key,
                        Key: fileInfo.Key.replace('/current/', '/prev/')
                    }).promise();
                })
            );
            // Delete all files from the 'current' folder
            const deletedResponse = await S3.deleteObjects(deleteParams).promise();
            console.debug('Delete objects...done', deletedResponse.Deleted);
        }

        // Finally returns a list of ICs to be loaded from VDS
        callback(null, conf);
    } catch (error) {
        console.error('lambda handler',error);
        throw error;
    }
}

