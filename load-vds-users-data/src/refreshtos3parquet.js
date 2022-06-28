const fs = require('fs')
const once = require('events')
const readline = require('readline')
const parquet = require('parquetjs')

const AWS = require('aws-sdk'),
    region = 'us-east-1'

require('console-stamp')(console)

const {initConfiguration, conf} = require("./conf");
const { getUsers } = require('./vdsActions')
const stream = require("stream");


// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel === 'info') {
    console.debug = function () {}
}

const args = process.argv.slice(2)
const table = args[0];
const bucket = args[1];
const folder = args[2];
console.debug('Arguments: ', args)
const ic = args.length > 3 ? args[3] : '';

AWS.config.update({ region: region });
const SECRET = process.env.SECRET || 'era-commons-connect';

// Create a Secrets Manager client
const client = new AWS.SecretsManager({
    region: region
});

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


// write S3 file
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

// Create a refresh mark as YYYYMMddHH
// const marker = formatDate(new Date());
const marker = '20220621185432';
const markerRecord = {
    vdsImport: marker,
    NEDId: 'DBMARKER',
    NIHORGACRONYM: 'DBMARKER',
    ic: ic ? ic : ''
}
const schema = new parquet.ParquetSchema({
    id: { type: 'UTF8'},
    content: { type: 'UTF8'}
});
const S3 = new AWS.S3();

async function run()
{
    console.log("Retrieve users data from VDS");

    console.debug('Getting secret parameters...');
    const configuration = await getSecretParameters();
    // Need to prepare private key here
    configuration.vds_cert = Buffer.from(configuration.vds_cert.replace(/\\n/g, '\n'), 'utf-8');
    initConfiguration(configuration);
    
    console.debug('Starting s3Upload...')
    s3Upload().then(r => {}); // Start async process to refresh DB

    console.debug('Starting and waiting for getUsers...')
    const usersCounter = await getUsers(ic, processVdsUsers);
    console.debug("Retrieved users - ", usersCounter, typeof usersCounter);
    console.debug("Writing the marker: ", marker);
    queueUsers.push(markerRecord);

    console.log("Imported " + usersCounter + " data records into DynamoDb table \"" + table + "\"");
    inProgress = false;
}

//Initialize array and start flag
const queueUsers = [];
let inProgress = true;
const s3Map = new Map();

run().then(r => {});

async function processVdsUsers(users, counter) {
    const prefix = 'processVdsUsers(' + counter + ') - ';
    console.debug(prefix + 'Processing ' + users.length + ' users' );
    users.forEach(user => {
        for (const attr of conf.vds.excludedAttributes) {
            delete user[attr];
        }
        queueUsers.push(user);
    });
}

async function s3Upload() {
    if (table === 'T') {
        // console.debug('Finished in test retrieval mode');
        return;
    }
    try {
        //prepare single s3 bucket
        let processedCounter = 0;
        console.log("Importing data into appropriate files");
        while (inProgress || queueUsers.length > 0) {
            let user = queueUsers.shift();
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
                //const writeStatus = wsIc.writeStream.write(user.UNIQUEIDENTIFIER + '\t' + JSON.stringify(user) + '\n');
                // if (!writeStatus) {
                //     console.debug('WriteStream wrote to ', ic, processedCounter, writeStatus);
                //     await sleep(200);
                // }

                processedCounter++;
                user = queueUsers.shift();
                if (processedCounter % 10000 === 0) {
                    console.info(processedCounter, ' records written...');
                }
            }
            console.debug('Sleeping for 3 sec')
            await sleep(3000);
        }

        console.debug('*****Closing Write Streams****')
        for (const [key, value] of s3Map.entries()) {
            // value.writeStream.end();
            await value.writer.close();
            console.debug('Waiting from uploadPromise of ', key);
            const response = await value.uploadPromise;
            console.debug('Got await from uploadPromise', response)
        }
        await sleep(1000); // last sleep - kludge

    } catch (err) {
        console.error(err);
    }

    console.info('Refresh is done');
    process.exit(0);
}


// add leading zero
function padTo2Digits(num) {
    return num.toString().padStart(2, '0');
}

function formatDate(date) {
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

const getEmail = (obj) => {

    let result = null;

    const proxyEmails = obj.proxyAddresses;
    if (proxyEmails) {
        if (Array.isArray(proxyEmails)) {
            proxyEmails.forEach(email => {
                const data = email.split(':');
                if (data[0] === 'SMTP') {
                    result = data[1];
                }
            });
        } else {
            const data = proxyEmails.split(':');
            if (data[0] === 'SMTP') {
                result = data[1];
            }
        }
    }
    return result;
};

const getBuilding = (obj) => {

    if (obj.BUILDINGNAME) {
        return 'BG ' + obj.BUILDINGNAME;
    } else {
        return 'N/A';
    }
};

const getDivision = (obj) => {

    let result = 'N/A';

    if (obj.NIHORGPATH) {
        const orgPathArr = obj.NIHORGPATH.split(' ') || [];
        const len = orgPathArr.length;

        if (len > 0 && len <= 2) {
            result = orgPathArr[len - 1];
        } else if (len > 2) {
            if (orgPathArr[1] === 'OD') {
                result = orgPathArr[2];
            } else {
                result = orgPathArr[1];
            }
        }
    }

    return result;

};

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
// process.exit();
// setTimeout(function () {
//     process.exit();
// }, 60000);
