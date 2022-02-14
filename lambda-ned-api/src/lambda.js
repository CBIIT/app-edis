const app = require('lambda-api')({version: 'v1.0', logger: {level: 'debug'}})
const AWS = require('aws-sdk'),
    region = 'us-east-1'

const { nedRoutes, config } = require('./nedApiRoutes')

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel === 'info') {
  console.debug = function () {}
}

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


app.register(nedRoutes, { prefix: '/nedapi'})
console.debug('The application has been registered');

let configuration;

module.exports.handler = async (event, context, callback) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.debug('Event:', JSON.stringify(event), configuration);

  if (!configuration) {
    console.debug('Getting secret parameters...');
    configuration = await getSecretParameters();
    // Configure the SOAP Web Service credentials
    console.debug('Configuration is about to set...', configuration.ned_wsdl, configuration.ned_wsdl_changes);
    config(configuration.ned_user, configuration.ned_pwd, configuration.ned_wsdl, configuration.ned_wsdl_changes);
    console.debug('Configuration is completed', configuration.ned_wsdl, configuration.ned_wsdl_changes);
  }

  console.debug('About to run event...');
  await app.run(event, context, callback);
}
