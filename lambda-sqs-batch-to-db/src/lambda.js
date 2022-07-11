'use strict'

const AWS = require('aws-sdk'),
      region = 'us-east-1'

// Environment variables
const logLevel = process.env['LOG_LEVEL'];
const table    = process.env['TABLE'];

// Set the console log level
if (logLevel && logLevel === 'info') {
  console.debug = function () {}
}

AWS.config.update({ region: region });
const docClient = new AWS.DynamoDB.DocumentClient({maxRetries: 25, retryDelayOptions: {base: 200}});

module.exports.handler = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.info('Lambda-sqs-batch-to-db', event);
  
  for (const record of event.Records) {
    const cmd = JSON.parse(record.body);
    if (cmd.action === 'update') {
      await dbUpdate(cmd.data);
      console.info('Update db records has been successful in range', cmd.marker, cmd.start, cmd.end);
    }
    else if (cmd.action === 'delete') {
      await dbUpdateDeleted(cmd.data, cmd.marker);
      console.info('Archive db records has been successful in range', cmd.marker, cmd.start, cmd.end);
    }
  }
}

async function dbUpdate(chunk) {
  if (table === 'T') {
    console.debug('Finished in test retrieval mode');
    return;
  }
  console.debug('Importing data into DynamoDb table',  table, 'with chunk', chunk.length);
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

async function dbUpdateDeleted(chunk, marker) {
  if (table === 'T') {
    console.debug('Finished in test deleted mode');
    return;
  }

  console.debug('Reading to be deleted data from DynamoDb table',  table, 'with chunk', chunk.length);
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
