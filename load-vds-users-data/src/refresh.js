
const AWS = require('aws-sdk'),
    region = 'us-east-1'

require('console-stamp')(console)

const {initConfiguration} = require("./conf");
const { getUsers } = require('./vdsActions')


// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel === 'info') {
    console.debug = function () {}
}

const args = process.argv.slice(2)
const table = args[0];
console.debug('Arguments: ', args)

//Set the AWS profile if needed
if (args.length > 1 && args[1]) {
    console.debug("Setting up AWS profile to ", args[1]);
    configOptions.credentials = new AWS.SharedIniFileCredentials({profile: args[1]});
}

AWS.config.update({ region: region });
const SECRET = process.env.SECRET || 'era-commons-connect';

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

const docClient = new AWS.DynamoDB.DocumentClient({maxRetries: 15, retryDelayOptions: {base: 200}});

async function run()
{
    console.log("Retrieve users data from VDS");

    console.debug('Getting secret parameters...');
    const configuration = await getSecretParameters();
    // Need to prepare private key here
    configuration.vds_cert = Buffer.from(configuration.vds_cert.replace(/\\n/g, '\n'), 'utf-8');
    initConfiguration(configuration);
    // Configure the SOAP Web Service credentials
    console.debug('Configuration is about to set...', configuration.ned_wsdl, configuration.ned_wsdl_changes);
    console.debug('Configuration is completed', configuration.ned_wsdl, configuration.ned_wsdl_changes);
    
    const usersResp = await getUsers('NCI');
    console.debug("Retrieved users - ", usersResp.length, typeof usersResp);
    
    if (table === 'T') {
        console.debug('Finished in test retrieval mode');
        return;
    }

    console.log("Importing data into DynamoDb table \"" + table + "\"");

    let n = 1;
    try {

        const allRecs = JSON.parse(fs.readFileSync(inputfile, 'utf-8'));
        const lastIndex = allRecs.length - 1;
            let batch = [];
        for (const [index, rec] of allRecs.entries()) {
            console.debug(n, JSON.stringify(rec));
            batch.push({
                PutRequest : {
                    Item: rec
                }
            });
            if (batch.length >= 25 || (index === lastIndex)) {

                var params = {
                    RequestItems: {
                        [table]: batch
                    }
                };

                const data = await docClient.batchWrite(params).promise();
                console.debug(n, 'result ', data);
                batch = [];
            }
            n++;
        }
        n--;
    } catch (e) {
        console.error(e);
    }

    console.log("Imported " + n + " data records into DynamoDb table \"" + inputfile + "\"");
}

run();

// process.exit();
// setTimeout(function () {
//     process.exit();
// }, 60000);
