const parquet = require('parquetjs');

const AWS = require('aws-sdk'),
    region = 'us-east-1'

const {initConfiguration} = require("./conf");
const {getAllProperties} = require("./getFredProps");
const { convertForDynamoDB, sleep } = require("./util");

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel === 'info') {
    console.debug = function () {
    }
    console.trace = function () {
    }
}

const s3bucket   = process.env['S3BUCKET'];
const s3folder   = process.env['S3FOLDER'];
const s3file   = process.env['S3FILE'];
const s3key = s3folder + '/' + s3file;

AWS.config.update({region: region});
const PARAMETER_PATH = process.env.PARAMETER_PATH || '/dev/app/eadis/fred/';

// Create a System Manager client
const client = new AWS.SSM();

async function getConfigurationParameters() {
    const data = await client.getParametersByPath({
        Path: PARAMETER_PATH,
        Recursive: true,
        WithDecryption: true
    }).promise();
    const result = {};
    data.Parameters.forEach((p) => {
        result[p.Name.slice(PARAMETER_PATH.length)] = p.Value;
    });
    console.debug('Parameters', result);
    return result;
}

let configuration;

const schema = new parquet.ParquetSchema({
  id: { type: 'UTF8'},
  content: { type: 'UTF8'}
});

const S3 = new AWS.S3();

module.exports.handler = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.debug('Event:', JSON.stringify(event), configuration);
    try {
        if (!configuration) {
            console.debug('Getting configuration parameters...');
            configuration = await getConfigurationParameters();
            // Need to prepare private key here
            initConfiguration(configuration);
        }

        console.debug('About to run event...');
        result = await getAllProperties()
        console.debug("dbExec...done. Records retrieved", result.GetAllPropertyResult.Property.length);
        const s3Entry =
            {
                bucket: s3bucket,
                key: s3key
            }

        await populateToS3Bucket(s3Entry, result.GetAllPropertyResult.Property);
        await closeWriteStreams(s3Entry);

        console.info("Completed - imported " + result.GetAllPropertyResult.Property.length + " data records into S3 bucket ");
    } catch (error) {
        console.error('Lambda handler', error);
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
        const {writeStream, uploadPromise} = createWriteStream(s3Entry.bucket, s3Entry.key);
        s3Entry.writeStream = writeStream;
        s3Entry.uploadPromise = uploadPromise;

        s3Entry.writer = await parquet.ParquetWriter.openStream(schema, writeStream);

        for (let row of rows) {
            const prop = convertForDynamoDB(row);

            console.debug('Append row...', prop.PropertyNumber)
            await s3Entry.writer.appendRow({
                id: '' + prop.PropertyNumber,
                content: JSON.stringify(prop)
            });
            // console.debug('Append row... done', prop.USER_ID)
        }
        console.info('Properties upload...done', rows.length);
    } catch (err) {
        console.error('Properties upload error', err); //TODO
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
    return {writeStream, uploadPromise}
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

