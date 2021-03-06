'use strict'

const readline = require('readline')
const AWS = require('aws-sdk'),
      region = 'us-east-1'
const { formatDate, getEmail, getBuilding, getDivision } = require('./util')

// Environment variables
const logLevel = process.env['LOG_LEVEL'];
const table    = process.env['TABLE'];

// Set the console log level
if (logLevel && logLevel === 'info') {
  console.debug = function () {}
}

AWS.config.update({ region: region });
const S3 = new AWS.S3();
const docClient = new AWS.DynamoDB.DocumentClient({maxRetries: 25, retryDelayOptions: {base: 200}});

module.exports.handler = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.info('Lambda-vds-delta-to-db', event);

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
    console.info('VDS delta S3 key is not defined - update db is skipped');
    return;
  }

  // extract bucket and key from S3 location
  const {bucket, key} = decodeS3URL(deltaS3path);
  if (bucket === null || key === null) {
    throw new Error('VDS delta S3 Path ' + deltaS3path + ' cannot be decoded');
  }
  console.debug('decomposed bucket and key', bucket, key);

  // Step 1 - update DB table with new or updated records from S3 VDS delta csv file 
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
    let bulkBuffer = [];

    for await (const rec of rl) {
      counter++;
      if (counter === 0) {
        continue; // skip the header
      }
      try {
        const user = processLine(rec, counter);
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
        bulkBuffer.push(user);
      } catch (e) {
        console.error('Parsing error', e);
        throw e;
      }
      if (bulkBuffer.length >= 25) {
        const chunk = bulkBuffer.slice();
        bulkBuffer = [];
        await dbUpdate(chunk, counter);
        console.debug('Stream on line event - resume command for line', counter);
      }
    }

    console.debug('Stream after close event - for', deltaS3path, 'lines leftover', bulkBuffer.length, counter);
    await dbUpdate(bulkBuffer, counter);
    if (counter > 0) {
      console.info('DB table has been updated successfully with ', counter, 'records.  Update Marker vdsImport is set to ', marker);
    }
    else {
      console.info('No records have been updated in DB table');
    }
  } catch (err) {
    console.error('Error in readline', err);
    throw err;
  }
}

// Step 2 - update DB table with deleted records from S3 VDS csv file 
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
        await dbUpdateDeleted(chunk, marker, counter);
      }
    }

    console.debug('Stream after close event - for', deltaS3deleted, 'lines leftover', bulkBuffer.length);
    await dbUpdateDeleted(bulkBuffer, marker, counter);

    if (counter > 0) {
      console.info('DB table records have been archived successfully for ', counter, 'records.  Update Marker vdsDelete is set to ', marker)
    }
    else {
      console.info('No records have been archived in DB table');
    }
  } catch (err) {
    console.error('Error in readline', err);
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

async function dbUpdate(chunk, counter) {
  if (table === 'T') {
    console.debug('Finished in test retrieval mode');
    return;
  }
  console.debug('Importing data into DynamoDb table',  table, 'with chunk', chunk.length, 'of', counter);
  let batch = [];
  for (const user of chunk) {
    batch.push({
      PutRequest : {
        Item: user
      }
    });
  }
  const params = {
    RequestItems: {
      [table]: batch
    }
  };
  const data = await processItems(params);
  console.debug('db refresh result ', data);
}

async function processItems(params) {
  
  const result = await docClient.batchWrite(params).promise();
  if(Object.keys(result.UnprocessedItems).length > 0) {
    params.RequestItems = result.UnprocessedItems;
    console.debug('processItems() - retry ', params.RequestItems);
    return await processItems(params);
  }
  return result;
}

async function dbUpdateDeleted(chunk, marker, counter) {
  if (table === 'T') {
    console.debug('Finished in test deleted mode');
    return;
  }

  console.debug('Reading to be deleted data from DynamoDb table',  table, 'with chunk', chunk.length, 'of', counter);
  let batch = [];
  for (const id of chunk) {
    batch.push({
      NEDId: id
    });
  }
  const params = {
    RequestItems: {
      [table]: {
        Keys: batch
      }
    }
  };
  const data = await docClient.batchGet(params)
  console.debug('Items to be deleted', data);
  for (const user of data) {
    user.vdsDelete = marker;
  }
  await dbUpdate(data);
}
