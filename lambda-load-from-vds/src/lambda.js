'use strict'

// require('console-stamp')(console);
const parquet = require('parquetjs')
const stream = require("stream");
const { initConfiguration, conf } = require("./conf");
const { getUsers }  = require('./vdsActions')
const { sleep, getDivision} = require("./util")

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

const schema = new parquet.ParquetSchema({
    id: { type: 'UTF8'},
    NIHORGPATH: { type: 'UTF8'},
    // Locality: { type: 'UTF8'},
    Division: { type: 'UTF8'},
    content: { type: 'UTF8'}
});

const S3 = new AWS.S3();

module.exports.handler = async (event, context) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.info('Lambda-load-user-data-from-VDS', event);
    
    const ic = event.ic;
    const divisions = event.divisions;
    const includeDivisions = !!(event.includeDivisions);
    const subKey = event.name ? event.name : ic;
    const s3Entry = {
        key: folder + '/' + 'storage_' + subKey + '.parquet'
    }
    
    try {
        const configuration = await getSecretParameters();
        // Need to prepare private key here
        configuration.vds_cert = Buffer.from(configuration.vds_cert.replace(/\\n/g, '\n'), 'utf-8');
        initConfiguration(configuration);

        console.debug('Starting and waiting for getUsers...')
        const usersCounter = await getUsers(ic, divisions, includeDivisions, processVdsUsers, s3Entry);
        console.debug("getUsers...done. Records retrieved", usersCounter, );


        await closeWriteStreams(s3Entry);
        console.info("Completed - imported " + usersCounter + " data records into S3 bucket ");
    } catch (error) {
        console.error('Lambda handler',error);
        throw error;
    }
}

async function processVdsUsers(users, counter, s3Entry) {
    const prefix = 'processVdsUsers(' + counter + ') - ';
    console.debug(prefix + 'Processing ' + users.length + ' users' );
    await batchUpload(users, counter, s3Entry);
}

async function batchUpload(queue, counter, s3Entry) {
    if (process.env.TEST) {
        // console.debug('Finished in test retrieval mode');
        return;
    }

    try {
        //prepare single s3 bucket
        while (queue.length > 0) {
            let user = queue.shift();
            while (typeof (user) !== 'undefined') {
                if (!s3Entry.writeStream) {
                    const {writeStream, uploadPromise} = createWriteStream(bucket, s3Entry.key);
                    const parquetWriter = await parquet.ParquetWriter.openStream(schema, writeStream);
                    s3Entry.writeStream = writeStream;
                    s3Entry.uploadPromise = uploadPromise;
                    s3Entry.writer = parquetWriter;

                    console.info('Created write stream for', s3Entry.key);
                }
                if (user.UNIQUEIDENTIFIER === undefined) {
                    user.UNIQUEIDENTIFIER = 'UNKNOWN';
                }
                console.debug('Append row...', user.UNIQUEIDENTIFIER, queue.length)
                await s3Entry.writer.appendRow({
                    id: user.UNIQUEIDENTIFIER,
                    NIHORGPATH: (user.NIHORGPATH) ? user.NIHORGPATH : 'unknown',
                    // Locality: (user.L) ? user.L : 'unknown',
                    Division: getDivision(user),
                    content: JSON.stringify(user)});
                console.debug('Append row... done', user.UNIQUEIDENTIFIER, queue.length)

                user = queue.shift();
            }
            console.info('Batch upload...done', counter);
        }
    } catch (err) {
        console.error('Batch upload error',err); //TODO
    }
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


