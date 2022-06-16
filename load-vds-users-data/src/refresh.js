
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
    
    // Create a refresh mark as YYYYMMddHH
    const usersCounter = await getUsers('NCI', processVdsUsers);
    console.debug("Retrieved users - ", usersCounter, typeof usersCounter);
    console.debug("Writing the marker: ", marker);
    const markerRecord = {
        vdsImport: marker,
        NEDId: 'DBMARKER',
        NIHORGACRONYM: 'DBMARKER'
    }
    const putParams = {
        TableName: table,
        Item: markerRecord
    }
    try {
        await docClient.put(putParams).promise();
    } catch (err) {
        console.error(err)
        process.exit(1);
    }
    
    console.log("Imported " + usersCounter + " data records into DynamoDb table \"" + table + "\"");
    process.exit(0);
}

const marker = formatDate(new Date());
run();

async function processVdsUsers(users) {
    console.debug('Processing ' + users.length + ' users' );
    users.forEach(user => {
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
        user.Locality - user.L;
        user.PointOfContactId = user.NIHPOC;
        user.Division = getDivision(user);
        user.Locality = user.L;
        user.Site = user.NIHSITE;
        user.Building = getBuilding(user);
        user.Room = user.ROOMNUMBER;
        user.vdsImport = marker;
    });

    if (table === 'T') {
        // console.debug('Finished in test retrieval mode');
        return;
    }

    console.log("Importing data into DynamoDb table \"" + table + "\"");

    let n = 1;
    try {

        const lastIndex = users.length - 1;
        let batch = [];
        for (const [index, user] of users.entries()) {
            // console.debug(n, JSON.stringify(rec));
            batch.push({
                PutRequest : {
                    Item: user
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
    } catch (e) {
        console.error(e);
    }
}

// add leading zero
function padTo2Digits(num) {
    return num.toString().padStart(2, '0');
}

function formatDate(date) {
    return (
        [
            date.getFullYear(),
            padTo2Digits(date.getMonth() + 1),
            padTo2Digits(date.getDate()),
            padTo2Digits(date.getHours()),
            padTo2Digits(date.getMinutes()),
            padTo2Digits(date.getSeconds()),
        ].join('')
    );
}

// process.exit();
// setTimeout(function () {
//     process.exit();
// }, 60000);
