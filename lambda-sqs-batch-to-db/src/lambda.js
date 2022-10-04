'use strict'

const DynamoDB = require('aws-sdk/clients/dynamodb')

// Environment variables
const logLevel = process.env['LOG_LEVEL'];
const table    = process.env['TABLE'];

// Set the console log level
if (logLevel && logLevel === 'info') {
  console.debug = function () {}
}

// AWS.config.update({ region: region });
const docClient = new DynamoDB.DocumentClient({maxRetries: 25, retryDelayOptions: {base: 200}});

module.exports.handler = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;

  // Logging all event records
  for (const record of event.Records) {
    console.info('Lambda-sqs-batch-to-db event',
        record.messageAttributes.action.stringValue, record.messageAttributes.marker.stringValue, 
        record.messageAttributes.start.stringValue, record.messageAttributes.end.stringValue);
  }

  try {
    for (const record of event.Records) {
      const cmd = JSON.parse(record.body);
      const action = record.messageAttributes.action.stringValue;
      const marker = record.messageAttributes.marker.stringValue;
      const start = record.messageAttributes.start.stringValue;
      const end = record.messageAttributes.end.stringValue;
      console.info('Lambda-sqs-batch-to-db to process', action, marker, start, end);
      if (action === 'update' && table !== 'T' && cmd.data.length > 0) {
        await dbUpdate(cmd.data);
        console.info('Update db records has been successful in range', marker, start, end);
      } else if (action === 'delete' && table !== 'T' && cmd.data.length > 0) {
        await dbUpdateDeleted(cmd.data, marker);
        console.info('Archive db records has been successful in range', marker, start, end);
      }
    }
  } catch (e) {
    console.error(e.message);
    throw(e);
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

  if (batch.length === 0) {
    return; // nothing to update
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
  
  if (batch.length === 0) {
    return; // nothing to archive
  }
  const params = {
    RequestItems: {
      [table]: {
        Keys: batch
      }
    }
  };
  const response = await docClient.batchGet(params).promise();
  console.debug('Items to be deleted', response);
  const data = response.Responses[table];
  for (const user of data) {
    user.vdsDelete = marker;
  }
  await dbUpdate(data);
}
