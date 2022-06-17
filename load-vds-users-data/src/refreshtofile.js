const fs = require('fs')
const once = require('events')

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

async function run()
{
    console.log("Retrieve users data from VDS");

    console.debug('Getting secret parameters...');
    const configuration = await getSecretParameters();
    // Need to prepare private key here
    configuration.vds_cert = Buffer.from(configuration.vds_cert.replace(/\\n/g, '\n'), 'utf-8');
    initConfiguration(configuration);
    // Configure the SOAP Web Service credentials
    // console.debug('Configuration is about to set...', configuration.ned_wsdl, configuration.ned_wsdl_changes);
    // console.debug('Configuration is completed', configuration.ned_wsdl, configuration.ned_wsdl_changes);
    
    console.debug('Starting fileRefresh...')
    fileRefresh().then(r => {}); // Start async process to refresh DB

    console.debug('Starting and waiting for getUsers...')
    const usersCounter = await getUsers('NCI', processVdsUsers);
    console.debug("Retrieved users - ", usersCounter, typeof usersCounter);
    console.debug("Writing the marker: ", marker);
    // const markerRecord = {
    //     vdsImport: marker,
    //     NEDId: 'DBMARKER',
    //     NIHORGACRONYM: 'DBMARKER'
    // }
    // const putParams = {
    //     TableName: table,
    //     Item: markerRecord
    // }
    // try {
    //     await docClient.put(putParams).promise();
    // } catch (err) {
    //     console.error(err)
    //     process.exit(1);
    // }
    
    console.log("Imported " + usersCounter + " data records into DynamoDb table \"" + table + "\"");
    inProgress = false;
}

// Create a refresh mark as YYYYMMddHH
const marker = formatDate(new Date());
//Initialize array and start flag
const queueUsers = [];
let inProgress = true;
const filesMap = new Map();

run().then(r => {});

async function processVdsUsers(users, counter) {
    const prefix = 'processVdsUsers(' + counter + ') - ';
    console.debug(prefix + 'Processing ' + users.length + ' users' );
    users.forEach(user => {
        user.NEDId = '' + user.UNIQUEIDENTIFIER;
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
        user.PointOfContactId = user.NIHPOC;
        user.Division = getDivision(user);
        user.Locality = user.L;
        user.Site = user.NIHSITE;
        user.Building = getBuilding(user);
        user.Room = user.ROOMNUMBER;
        user.vdsImport = marker;
        queueUsers.push(user);
    });
}

async function fileRefresh() {

    if (table === 'T') {
        // console.debug('Finished in test retrieval mode');
        return;
    }
    let processedCounter = 0;
    console.log("Importing data into appropriate files");
    while (inProgress || queueUsers.length > 0) {
        let user = queueUsers.shift();
        while (typeof (user) !== 'undefined') {
            const ic = user.NIHORGACRONYM ? user.NIHORGACRONYM : '';
            let stream = filesMap.get(ic);
            if (!stream) {
                stream = fs.createWriteStream('storage_' + ic + '.txt', { flags: 'w'})
                filesMap.set(ic, stream);
                console.log('Create', typeof stream, 'for', ic)
            }
            const writeStatus = stream.write(JSON.stringify(user) + '\n');
            if (!writeStatus) {
                console.debug('WriteStream wrote to ', ic, processedCounter, writeStatus);
                await sleep(200);
            }

            processedCounter++;
            user = queueUsers.shift();
            if (processedCounter % 10000 === 0) {
                console.info(processedCounter, ' records written...');
            }
        }
        console.debug('Sleeping for 1 sec')
        await sleep(1000);
    }
    
    for (const [key, value] of filesMap.entries()) {
        value.end();
    }
    await sleep(1000); // last sleep - kludge

    console.info('Refresh is done');
    process.exit(0);
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

const getEmail = (obj) => {

    let result = null;

    const proxyEmails = obj.proxyAddresses;
    if (proxyEmails) {
        if (Array.isArray(proxyEmails)) {
            proxyEmails.forEach(email => {
                const data = email.split(':');
                if (data[0] === 'SMTP') {
                    result = data[1];
                }
            });
        } else {
            const data = proxyEmails.split(':');
            if (data[0] === 'SMTP') {
                result = data[1];
            }
        }
    }
    return result;
};

const getBuilding = (obj) => {

    if (obj.BUILDINGNAME) {
        return 'BG ' + obj.BUILDINGNAME;
    } else {
        return 'N/A';
    }
};

const getDivision = (obj) => {

    let result = 'N/A';

    if (obj.NIHORGPATH) {
        const orgPathArr = obj.NIHORGPATH.split(' ') || [];
        const len = orgPathArr.length;

        if (len > 0 && len <= 2) {
            result = orgPathArr[len - 1];
        } else if (len > 2) {
            if (orgPathArr[1] === 'OD') {
                result = orgPathArr[2];
            } else {
                result = orgPathArr[1];
            }
        }
    }

    return result;

};

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
// process.exit();
// setTimeout(function () {
//     process.exit();
// }, 60000);
