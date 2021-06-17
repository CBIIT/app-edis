var AWS = require("aws-sdk");

const args = process.argv.slice(2)
const table = args[0];
console.debug('Arguments: ', args)

const configOptions = {
    region: "us-east-1"
}

//Set the AWS profile if needed
if (args.length > 1 && args[1]) {
    console.debug("Setting up AWS profile to ", args[1]);
    configOptions.credentials = new AWS.SharedIniFileCredentials({profile: args[1]});
}

AWS.config.update(configOptions);

const docClient = new AWS.DynamoDB.DocumentClient({maxRetries: 15, retryDelayOptions: {base: 200}});

async function truncate(tableName) {
    const rows = await docClient.scan({
        TableName: tableName,
        AttributesToGet: ['USER_ID']
    }).promise();

    console.log(`Deleting ${rows.Items.length} records`);
    for (let element of rows.Items) {
        console.log('Deleting', element)
        await docClient.delete({
            TableName: tableName,
            Key: element
        }).promise();
    }
}

truncate(table);

// process.exit();
// setTimeout(function () {
//     process.exit();
// }, 60000);
