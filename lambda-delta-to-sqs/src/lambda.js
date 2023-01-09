'use strict'

const readline = require('readline')
const AWS = require('aws-sdk'),
      region = 'us-east-1'
const { formatDate } = require('./util')

// Environment variables
const logLevel = process.env['LOG_LEVEL'];
const maxMessageSize = process.env['MAX_SIZE'] || 262144;

// Set the console log level
if (logLevel && logLevel === 'info') {
  console.debug = function () {}
}

AWS.config.update({ region: region });
const S3 = new AWS.S3();
const SQS = new AWS.SQS();

/**
 * @param event - input event structure:
 * {
 *     delta   -  S3 key to "delta" csv file 
 *     deleted - S3 key to "deleted" csv file
 *     sqs_url_key - environment variable name to select URL for SQS queue
 * }
 */
module.exports.handler = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.info('Lambda-delta-to-sqs', event);

  const deltaS3path = event['delta'];
  const deltaS3deleted = event['deleted'];
  const sqs_url_key = event['sqs_url_key'];
  
  let sqsQueueUrl = '';
  if (sqs_url_key !== undefined && sqs_url_key !== '') {
    sqsQueueUrl = process.env[sqs_url_key] || '';
  }
  if (sqsQueueUrl === '') {
    throw new Error('Event parameter sqs_url_key is missing or incorrect: ' + sqs_url_key);
  }

// Create a refresh mark as YYYYMMddHH
  const marker = '' + formatDate(new Date());

  // Step 1 - send to SQS chunks with new or updated records from S3 delta csv file 
  await processRecords(sqsQueueUrl, deltaS3path, marker, 'update');
// Step 2 - send messages to SQS  with deleted records from S3 csv file 
  await processRecords(sqsQueueUrl, deltaS3deleted, marker, 'delete');
}

async function processRecords(sqsQueueUrl, s3url, marker, action)
{
  if (!sqsQueueUrl || !s3url) {
    console.info('delta S3 url or key is not defined - update is skipped', sqsQueueUrl, s3url);
    return;
  }

  // extract bucket and key from S3 location
  const {bucket, key} = decodeS3URL(s3url);
  if (bucket === null || key === null) {
    throw new Error('Delta S3 Path ' + s3url + ' cannot be decoded');
  }
  console.debug('decomposed bucket and key', bucket, key);

  let counter = -1;
  let bulkBuffer = [];
  let msgSize = 0;

  try {
    const input = S3.getObject({
      Bucket: bucket,
      Key: key
    }).createReadStream();
    const rl = readline.createInterface({
      input: input,
      crlfDelay: Infinity
    });


    for await (const rec of rl) {
      if (counter < 0) {
        counter++;
        continue; // skip the header
      }
      let sRow;
      if (action === 'update') {
        try {
          const row = processLine(rec, counter);
          // Enhance record with timestamp
          row['tsImport'] = marker;
          sRow = JSON.stringify(row);
        } catch (e) {
          console.error('Parsing error', e);
          throw e;
        }
      }
      else {
        sRow = rec.slice(1, -1);
      }

      // push user for bulk update
      const userSize = Buffer.byteLength(sRow, 'utf8'); 
      msgSize +=  userSize + 1; // comma between user definitions
      const overflow = msgSize >= maxMessageSize; 
      if (!overflow) {
        bulkBuffer.push(row);
        counter++;
      }

      if (bulkBuffer.length >= 25 || overflow) {
        const chunk = bulkBuffer.slice();
        bulkBuffer = [];
        msgSize = 0;
        await sqsSend(sqsQueueUrl, chunk, marker, counter, action);
        if (overflow) {
          bulkBuffer.push(row);
          counter++;
          msgSize = userSize + 2; // open and close square brackets
        }
        console.debug('Stream on line event - resume command for line', counter);
      }
    }

    console.debug('Stream after close event - for', s3url, 'lines leftover', bulkBuffer.length, counter);
    await sqsSend(sqsQueueUrl, bulkBuffer, marker, counter, action);
    if (counter > 0) {
      console.info('Data have been send to SQS successfully with ', counter, 'records.  Update Marker tsImport is set to ', marker);
    }
    else {
      console.info('No records have been sent to SQS');
    }
  } catch (err) {
    console.error('Error in sqsSend', counter, ' ', JSON.stringify(bulkBuffer).length, err);
    throw err;
  }
}

function decodeS3URL(path) {
  let bucket = null;
  let key = null;
  if (path && path.startsWith('s3://')) {
    const s = path.slice(5);
    console.debug('removed prefix', s);
    bucket = s.substring(0, s.indexOf('/'))
    key = s.slice(bucket.length + 1);
  }
  return { bucket, key };
}

/**
 * Convert a string from S3 delta file into JSON user data
 * @param line - given input string 
 * @returns {any} - enhanced user JSON record
 */
function processLine(line) {
  line = line.replace(/""/g, '"');
  line = line.slice(1,-1);
  // if (counter < 2) {
  //   console.debug('unprocessed record', line);
  // }
  try {
    return JSON.parse(line);
  }
  catch (e) {
    console.error('JSON parse failed for record', counter);
    console.error('Failed line:', line);
    throw e;
  }
}

async function sqsSend(sqsQueueUrl, chunk, marker, counter, action) {
  if (!sqsQueueUrl || sqsQueueUrl === 'T') {
    console.debug('Finished in test retrieval mode');
    return;
  }
  if (chunk.length === 0) {
    return;
  }
  const start = '' + (counter - chunk.length);
  const end = '' + counter;
  const sChunk = JSON.stringify({
    data: chunk
  });
  const sChunkLength = Buffer.byteLength(sChunk, 'urf8');
  console.info('Sending data into SQS with chunk', chunk.length, 'of', counter, sChunkLength);

  const params = {
    MessageBody: sChunk,
    QueueUrl: sqsQueueUrl,
    MessageAttributes: {
      'action': {
        DataType: 'String',
        StringValue: action
      },
      'start': {
        DataType: 'String',
        StringValue: start
      },
      'end': {
        DataType: 'String',
        StringValue: end
      },
      'marker': {
        DataType: 'String',
        StringValue: marker
      }
    }
  }
  const bodyLength = params.MessageBody.length;
  const result = await SQS.sendMessage(params).promise();
  console.info('Lambda-delta-to-sqs sent', action, marker, start, end, bodyLength, sChunkLength);
  console.debug('sqs sent result ', result);
}
