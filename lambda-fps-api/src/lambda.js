const app = require('lambda-api')({version: 'v1.0', logger: {level: 'debug'}});
const AWS = require('aws-sdk'),
    region = 'us-east-1';

const { nvRoutes } = require('./nvApiRoutes');
const {initConfiguration} = require("./conf");
const { convertParametersToJson } = require ("./util");

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel === 'info') {
  console.debug = function () {};
  console.trace = function () {};
} else if (logLevel && logLevel === 'debug') {
  console.trace = function () {}
}
AWS.config.update({ region: region });
const PARAMETER_PATH = process.env.PARAMETER_PATH || '/dev/app/eadis/fps/';

// Create AWS SystemManager client
const client = new AWS.SSM();

async function getConfigurationParameters() {
  const data = await client.getParametersByPath({
    Path: PARAMETER_PATH,
    Recursive: true,
    WithDecryption: true }).promise();
  return convertParametersToJson(data, PARAMETER_PATH);
}


app.register(nvRoutes, { prefix: '/fpsapi/v1'})
console.debug('The application has been registered');

let configuration;

module.exports.handler = async (event, context, callback) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.debug('Event:', JSON.stringify(event), configuration);

  if (!configuration) {
    console.debug('Getting configuration parameters...');
    configuration = await getConfigurationParameters();
    // Need to prepare private key here
    initConfiguration(configuration);
  }

  console.debug('About to run event...');
  await app.run(event, context, callback);
};
