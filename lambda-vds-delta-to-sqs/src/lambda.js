'use strict'

const readline = require('readline')
const AWS = require('aws-sdk'),
      region = 'us-east-1'
const { formatDate, getEmail, getBuilding, getDivision } = require('./util')

// Environment variables
const logLevel = process.env['LOG_LEVEL'];
const queueUrl = process.env['SQS_URL'];
const maxMessageSize = process.env['MAX_SIZE'] || 262144;

// Set the console log level
if (logLevel && logLevel === 'info') {
  console.debug = function () {}
}

AWS.config.update({ region: region });
const S3 = new AWS.S3();
const SQS = new AWS.SQS();

module.exports.handler = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.info('Lambda-vds-delta-to-sqs', event);

  const deltaS3path = event.delta;
  const deltaS3deleted = event.deleted;


// Create a refresh mark as YYYYMMddHH
  const marker = formatDate(new Date());

  await processUpdatedRecords(deltaS3path, marker);
  await processDeletedRecords(deltaS3deleted, marker);
}

async function processUpdatedRecords(deltaS3path, marker)
{
  if (!deltaS3path) {
    console.info('VDS delta S3 key is not defined - update is skipped');
    return;
  }

  // extract bucket and key from S3 location
  const {bucket, key} = decodeS3URL(deltaS3path);
  if (bucket === null || key === null) {
    throw new Error('VDS delta S3 Path ' + deltaS3path + ' cannot be decoded');
  }
  console.debug('decomposed bucket and key', bucket, key);

  // Step 1 - send to SQS chunks with new or updated records from S3 VDS delta csv file 
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
      let user;
      try {
        user = processLine(rec, counter);
      } catch (e) {
        console.error('Parsing error', e);
        throw e;
      }

      // Enhance user record with additional fields including timestamp
      user.NEDId = user.UNIQUEIDENTIFIER;
      user.FirstName = user.GIVENNAME;
      user.MiddleName = user.MIDDLENAME;
      user.LastName = user.NIHMIXCASESN;
      user.Email = getEmail(user);
      user.Phone = user.TELEPHONENUMBER;
      user.Classification = user.ORGANIZATIONALSTAT;
      user.SAC = user.NIHSAC;
      user.AdministrativeOfficerId = user.NIHSERVAO;
      user.COTRId = user.NIHCOTRID;
      user.ManagerId = user.MANAGER;
      user.Locality = user.L;
      user.PointOfContactId = user.NIHPOC;
      user.Division = getDivision(user);
      user.Locality = user.L;
      user.Site = user.NIHSITE;
      user.Building = getBuilding(user);
      user.Room = user.ROOMNUMBER;
      user.vdsImport = marker;

      // push user for bulk update
      const userSize = Buffer.byteLength(JSON.stringify(user), 'utf8'); 
      msgSize +=  userSize + 1; // comma between user definitions
      const overflow = msgSize >= maxMessageSize; 
      if (!overflow) {
        bulkBuffer.push(user);
        counter++;
      }

      if (bulkBuffer.length >= 25 || overflow) {
        const chunk = bulkBuffer.slice();
        bulkBuffer = [];
        msgSize = 0;
        await sqsSend(chunk, marker, counter);
        if (overflow) {
          bulkBuffer.push(user);
          counter++;
          msgSize = userSize + 2; // open and close square brackets
        }
        console.debug('Stream on line event - resume command for line', counter);
      }
    }

    console.debug('Stream after close event - for', deltaS3path, 'lines leftover', bulkBuffer.length, counter);
    await sqsSend(bulkBuffer, marker, counter);
    if (counter > 0) {
      console.info('Data have been send to SQS successfully with ', counter, 'records.  Update Marker vdsImport is set to ', marker);
    }
    else {
      console.info('No records have been sent to SQS');
    }
  } catch (err) {
    console.error('Error in sqsSend', counter, ' ', JSON.stringify(bulkBuffer).length, err);
    throw err;
  }
}

// Step 2 - send messages to SQS  with deleted records from S3 VDS csv file 
async function processDeletedRecords(deltaS3deleted, marker)
{
  if (!deltaS3deleted) {
    console.info('VDS deleted S3 key is not defined - update deleted records in db is skipped');
    return;
  }

  // extract bucket and key from S3 location
  const {bucket, key} = decodeS3URL(deltaS3deleted);
  if (bucket === null || key === null) {
    throw new Error('VDS deleted records S3 Path ' + deltaS3deleted + ' cannot be decoded');
  }

  try {
    const input = S3.getObject({
      Bucket: bucket,
      Key: key
    }).createReadStream();
    const rl = readline.createInterface({
      input: input,
      crlfDelay: Infinity
    });

    let counter = -1;
    let bulkBuffer = [];  // array of primary key strings

    for await (const rec of rl) {
      counter++;
      if (counter === 0) {
        continue; // skip the header
      }
      bulkBuffer.push(rec.slice(1, -1)); // remove surrounding double quotes
      
      if (bulkBuffer.length >= 25) {
        const chunk = bulkBuffer.slice();
        bulkBuffer = [];
        await sqsSendDeleted(chunk, marker, counter);
      }
    }

    console.debug('Stream after close event - for', deltaS3deleted, 'lines leftover', bulkBuffer.length);
    await sqsSendDeleted(bulkBuffer, marker, counter);

    if (counter > 0) {
      console.info('SQS messages to archive records have been sent successfully for ', counter, 'records.  Update Marker vdsDelete is set to ', marker)
    }
    else {
      console.info('No SQS messages have been sent to archive records in DB table');
    }
  } catch (err) {
    console.error('Error in sqsSendDeleted', counter, ' ', JSON.stringify(bulkBuffer).length, err);
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
 * Convert a string from S3 VDS delta file into JSON user data
 * @param line - given input string 
 * @param counter - current counter (for logging purposes)
 * @returns {any} - enhanced user JSON record
 */
function processLine(line, counter) {
  line = line.replace(/""/g, '"');
  line = line.slice(1,-1);
  // if (counter < 2) {
  //   console.debug('unprocessed record', line);
  // }
  try {
    const rec = JSON.parse(line);
    if (counter < 2) {
      console.debug('processed record', rec);
    }
    return rec;
  }
  catch (e) {
    console.error('JSON parse failed for record', counter);
    console.error('Failed line:', line);
    throw e;
  }
}

async function sqsSend(chunk, marker, counter) {
  // if (tmpDebug === 'Y') {
  //   const sChunk = JSON.stringify(chunk);
  //   const ind = sChunk.indexOf(checkString);
  //   if (ind >= 0) {
  //     console.info('Testing data into SQS with chunk', chunk.length, 'of', counter);
  //     console.error('Error in data - index', ind, sChunk.length);
  //     console.error('Error in data', sChunk);
  //     console.error('Error in subdata', sChunk.slice(0, ind - 1));
  //   }
  //   return;
  // }
  if (!queueUrl || queueUrl === 'T') {
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
    QueueUrl: queueUrl,
    MessageAttributes: {
      'action': {
        DataType: 'String',
        StringValue: 'update'
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
  console.info('Lambda-vds-delta-to-sqs sent', 'update', marker, start, end, bodyLength, sChunkLength);
  console.debug('sqs sent result ', result);
}

async function sqsSendDeleted(chunk, marker, counter) {
  if (!queueUrl || queueUrl === 'T') {
    console.debug('Finished in test deleted mode');
    return;
  }
  if (chunk.length === 0) {
    return;
  }
  const start = '' + (counter - chunk.length);
  const end = '' + counter;
  const params = {
    MessageBody: JSON.stringify({
      data: chunk
    }),
    QueueUrl: queueUrl,
    MessageAttributes: {
      'action': {
        DataType: 'String',
        StringValue: 'delete'
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
  console.info('Lambda-vds-delta-to-sqs sent', 'delete', marker, start, end, bodyLength);
  console.debug('sqs sent result ', result);
}
