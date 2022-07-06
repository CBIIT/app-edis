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

/**
 * Function to move S3 objects from one folder to another relative to the 'based path' defined in S3FOLDER
 * environment variable OR delete S3 objects if the destination folder is not defined
 * 
 * @param event - JSON object:
 * {
 *     src: 'xxx', -- source sub folder to move objects from (required)
 *     dst: 'yyy'  -- destination sub folder to move objects to (optional - undefined or empty - just delete from src)
 * }
 * @param context - event context
 * @param callback - return JSON array of ICs (TBD)  or error
 * 
 */
module.exports.handler = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.info('Lambda-prepare-s3-for-vds', event);
    
    // Input validation
    if (!event.src || event.src.length === 0) {
        callback('Error - src folder is not defined');
        return;
    }
    
    const fromFolder = event.src;
    const toFolder = event.dst;
    const fromPrefix = folder + '/' + fromFolder + '/';
    const toPrefix = (toFolder && toFolder.length > 0) ? folder + '/' + toFolder + '/' : ''; 

    try {
    const deleteParams = {
        Bucket: bucket,
        Delete: { Objects: [] }
    };

    // Step1.  Remove all files from 'dst' folder (if dst folder is defined
    console.debug('Removing all files from dst folder of S3...', toFolder);
    if (toPrefix.length > 0) {
        const listParams = {
            Bucket: bucket,
            Prefix: toPrefix
        }
        let fileList = await S3.listObjectsV2(listParams).promise();

        console.debug('Preparing list of objects to delete...', fileList.Contents.length);
        if (fileList && fileList.Contents.length > 0) {
            fileList.Contents.forEach((content) => {
                deleteParams.Delete.Objects.push({ Key: content.Key});
                console.debug('Clean up file', content.Key);
            });
            console.info('Prepare to cleanup...done', deleteParams.Delete.Objects.length, 'objects')
            console.debug('About to delete...', deleteParams)
            const deletedResponse = await S3.deleteObjects(deleteParams).promise();
            console.debug('Delete objects...done', deletedResponse.Deleted);
        }
    }
        
        // Step2. Get a list of files in 'src' folder
        const fromListParams = {
            Bucket: bucket,
            Prefix: fromPrefix
        }
        const fromFileList = await S3.listObjectsV2(fromListParams).promise();
        console.debug('Preparing list of objects to move...', fromFileList.Contents.length);

        if (fromFileList && fromFileList.Contents.length > 0) {

            // Step3. Move all files from src to dst folder if dst folder is defined
            if (toPrefix.length > 0) {
                await Promise.all(
                    fromFileList.Contents.map(async (fileInfo) => {
                        console.debug('Copying', fileInfo.Key, ' to ', fileInfo.Key.replace(fromPrefix, toPrefix));
                        await S3.copyObject({
                            Bucket: bucket,
                            CopySource: bucket + '/' + fileInfo.Key,
                            Key: fileInfo.Key.replace(fromPrefix, toPrefix)
                        }).promise();
                        console.debug('Copying...done');
                    })
                );
            }

            // Step4. Delete all files from the 'src' folder
            deleteParams.Delete.Objects = [];
            fromFileList.Contents.forEach((content) => {
                deleteParams.Delete.Objects.push({ Key: content.Key});
                console.debug('Delete file', content.Key);
            });
            console.debug('Deleting objects...', deleteParams.Delete.Objects);
            const deletedResponse = await S3.deleteObjects(deleteParams).promise();
            console.debug('Delete objects...done', deletedResponse.Deleted);
        }

        // Finally returns a list of ICs to be loaded from VDS
        console.info('Move files from', fromPrefix, '...done');
        callback(null, conf); // TBD
    } catch (error) {
        console.error('error lambda handler',error);
        throw error;
    }
}

