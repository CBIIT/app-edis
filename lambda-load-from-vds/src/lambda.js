'use strict'

require('console-stamp')(console);
const parquet = require('parquetjs')
const stream = require("stream");
const { initConfiguration, conf } = require("./conf");
const { getUsers }  = require('./vdsActions')
const { formatDate } = require("./util")

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
        console.error('SecretsManager Success: NO ERR OR DATA');
        throw new Error('SecretsManager Success: NO ERR OR DATA');
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
    content: { type: 'UTF8'}
});

const S3 = new AWS.S3();

module.exports.handler = async (event, context) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.debug('Lambda-cds-user-delta', event);
    
    const ic = event.ic;
    
    const marker = formatDate(new Date());
    const markerRecord = {
        vdsImport: marker,
        NEDId: 'DBMARKER',
        NIHORGACRONYM: 'DBMARKER',
        ic: ic ? ic : ''
    }
    
    try {
        const configuration = await getSecretParameters();
        // Need to prepare private key here
        configuration.vds_cert = Buffer.from(configuration.vds_cert.replace(/\\n/g, '\n'), 'utf-8');
        initConfiguration(configuration);

        console.debug('Starting and waiting for getUsers...')
        const s3Map = new Map();

        const usersCounter = await getUsers(ic, processVdsUsers, s3Map);
        console.debug("Retrieved users - ", usersCounter, typeof usersCounter);

        console.debug("Writing the marker: ", marker);
        const queueUsers = [];
        queueUsers.push(markerRecord);
        await batchUpload(queueUsers, s3Map);

        await closeWriteStreams(s3Map);
        console.info("Imported " + usersCounter + " data records into S3 bucket ");
    } catch (error) {
        console.error(error);
        throw error;
    }
}

async function processVdsUsers(users, counter, s3Map) {
    const prefix = 'processVdsUsers(' + counter + ') - ';
    console.debug(prefix + 'Processing ' + users.length + ' users' );
    users.forEach(user => {
        for (const attr of conf.vds.excludedAttributes) {
            delete user[attr];
        }
    });
    await batchUpload(users, s3Map, counter);
}

async function batchUpload(queue, s3Map, counter) {
    if (process.env.TEST) {
        // console.debug('Finished in test retrieval mode');
        return;
    }

    try {
        //prepare single s3 bucket
        // console.log("Importing data into appropriate files");
        while (queue.length > 0) {
            let user = queue.shift();
            while (typeof (user) !== 'undefined') {
                const ic = user.NIHORGACRONYM ? user.NIHORGACRONYM : 'UNKNOWN';
                let wsIc = s3Map.get(ic);
                if (!wsIc) {
                    const key = (ic === 'DBMARKER') ?
                        ((user.ic && user.ic.length > 0) ? folder + '/current_marker_' + user.ic + '.mrk' :
                            folder + '/current_marker.mrk')
                        : folder + '/current/' + 'storage_' + ic + '.txt';
                    const {writeStream, uploadPromise} = createWriteStream(bucket, key);
                    const parquetWriter = await parquet.ParquetWriter.openStream(schema, writeStream);

                    wsIc = {
                        writeStream: writeStream,
                        uploadPromise: uploadPromise,
                        writer: parquetWriter
                    }
                    s3Map.set(ic, wsIc);
                    console.log('Created write stream for', key);
                }
                if (user.UNIQUEIDENTIFIER === undefined) {
                    user.UNIQUEIDENTIFIER = 'UNKNOWN';
                }
                await wsIc.writer.appendRow({id: user.UNIQUEIDENTIFIER, content: JSON.stringify(user)});

                user = queue.shift();
            }
            console.debug('Batch has been written', counter);
        }
    } catch (err) {
        console.error(err); //TODO
    }
}

async function closeWriteStreams(s3Map) {
        console.debug('*****Closing Write Streams****')
        for (const [key, value] of s3Map.entries()) {
            // value.writeStream.end();
            await value.writer.close();
            console.debug('Waiting from uploadPromise of ', key);
            const response = await value.uploadPromise;
            console.debug('Got await from uploadPromise', response)
        }
        await sleep(1000); // last sleep - kludge
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

