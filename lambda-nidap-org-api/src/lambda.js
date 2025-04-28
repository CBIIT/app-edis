const app = require('lambda-api')({version: 'v1.0', logger: {level: 'debug'}})
const AWS = require('aws-sdk'),
    region = 'us-east-1'

const { orgRoutes } = require("./orgApiRoutes");
const { initConfiguration } = require("./conf");
const { nidapApiRoutesV2} = require("./nidapApiRoutesV2");
const { convertParametersToJson } = require("./util");

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel === 'info') {
  console.debug = function () {}
  console.trace = function () {}
}
if (logLevel && logLevel === 'debug') {
  console.trace = function () {}
}

AWS.config.update({ region: region });
const PARAMETER_PATH = process.env.PARAMETER_PATH || '/dev/app/eadis/nidap/';

// Create a Secrets Manager client
const client = new AWS.SSM();

async function getConfigurationParameters() {
  let data = [];
  let resp = {};
  do {
    let params = {
      Path: PARAMETER_PATH,
      Recursive: true,
      WithDecryption: true
    }
    if (resp.NextToken) {
      params.NextToken = resp.NextToken;
    }
    resp = await client.getParametersByPath(params).promise();
    data = data.append(resp.Parameters);
  } while (resp.NextToken !== undefined);
  return convertParametersToJson(data, PARAMETER_PATH);
}

app.register(orgRoutes, { prefix: '/orgapi/nidap/v1'});
app.register(nidapApiRoutesV2, { prefix: '/dataapi/v2'});
console.debug('The application has been registered');

let configuration;

module.exports.handler = async (event, context, callback) => {
  context.callbackWaitsForEmptyEventLoop = false;
  console.debug('Event:', JSON.stringify(event), configuration);

  if (!configuration) {
    console.debug('Getting configuration parameters...');
    configuration = await getConfigurationParameters();
    // Need to prepare private key here
    initConfiguration(configuration);
  }

  console.debug('About to run event...');
  await app.run(event, context, callback);
}
