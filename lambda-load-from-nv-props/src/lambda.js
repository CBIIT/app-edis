'use strict'

// require('console-stamp')(console);
const parquet = require('parquetjs')
const stream = require("stream");
const { initConfiguration, conf, PROPSQL } = require("./conf");
const { getProps }  = require('./nvActions')
const { convertForDynamoDB, sleep } = require("./util")

const AWS = require('aws-sdk'),
    region = 'us-east-1'

AWS.config.update({ region: region });
const SECRET = process.env.SECRET || 'era-commons-connect';

// Create a Secrets Manager client
const client = new AWS.SecretsManager({
    region: region
});

// Environment variables
const logLevel = process.env['LOG_LEVEL'];
const bucket   = process.env['S3BUCKET'];
const folder   = process.env['S3FOLDER'];
const current = 'current_props';
const key = folder + '/' + current + '/' + 'storage.parquet';

// Set the console log level
if (logLevel && logLevel === 'info') {
    console.debug = function () {}
}

async function getSecretParameters() {
    const data = await client.getSecretValue({SecretId: SECRET}).promise();
    if (data) {
        if (data.SecretString) {
            return JSON.parse(data.SecretString);
        }
    }
    else {
        console.error('SecretsManager: NO ERR OR DATA in response');
        throw new Error('SecretsManager: NO ERR OR DATA in response');
    }
}

//TODO
const schema = new parquet.ParquetSchema({
    id: { type: 'UTF8'},
    CURR_NED_ID: { type: 'UTF8'},
    content: { type: 'UTF8'}
});

const S3 = new AWS.S3();

module.exports.handler = async (event, context) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.info('Lambda-load-props-from-nVision', event);
    
    
    try {
        const configuration = await getSecretParameters();
        initConfiguration(configuration);

        console.debug('Starting and waiting for getProps...')
        const result = await getProps({
            user: conf.nv.user,
            pwd: conf.nv.pwd,
            connectString: conf.nv.connectString
        }, PROPSQL);
        console.debug("getProps...done. Records retrieved", result.rows.length );
        const s3Entry = { key: key }

        await populateToS3Bucket(s3Entry, result.rows);
        await closeWriteStreams(s3Entry);
        
        console.info("Completed - imported " + result.rows.length + " data records into S3 bucket ");
    } catch (error) {
        console.error('Lambda handler',error);
        throw error;
    }
}

async function populateToS3Bucket(s3Entry, rows) {
    if (process.env.TEST) {
        console.debug('Finished in test retrieval mode');
        return;
    }

    try {
        //prepare single s3 bucket
        console.info('Created write stream for', s3Entry.key);
        const {writeStream, uploadPromise} = createWriteStream(bucket, s3Entry.key);
        s3Entry.writeStream = writeStream;
        s3Entry.uploadPromise = uploadPromise;

        s3Entry.writer = await parquet.ParquetWriter.openStream(schema, writeStream);

        for (let row of rows) {
            const prop = convertForDynamoDB(row);

            console.debug('Append row...', prop.ASSET_KEY)
            await s3Entry.writer.appendRow({
                id: '' + prop.ASSET_KEY,
                CURR_NED_ID: '' + prop.CURR_NED_ID,
                content: JSON.stringify(prop)});
            // console.debug('Append row... done', prop.ASSET_KEY)
        }
        console.info('Properties upload...done', counter);
    } catch (err) {
        console.error('Properties upload error',err); //TODO
    }
}

// Create Write Stream for S3 file
function createWriteStream(Bucket, Key) {
    const writeStream = new stream.PassThrough()
    writeStream.close = (cb) => writeStream.end(cb);
    const uploadPromise = S3
        .upload({
            Bucket,
            Key,
            Body: writeStream
        })
        .promise();
    return { writeStream, uploadPromise }
}


async function closeWriteStreams(s3Entry) {
    console.debug('*****Closing Write Streams****')
    if (s3Entry.writer) {
        // value.writeStream.end();
        await s3Entry.writer.close();
        console.debug('uploadPromise of ', s3Entry.key);
        const response = await s3Entry.uploadPromise;
        console.info('uploadPromise...done', response)
    }
    await sleep(1000); // last sleep - kludge
}


