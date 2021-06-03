var AWS = require("aws-sdk");
var fs = require('fs');

AWS.config.update({
   region: "us-east-1"
});

const docClient = new AWS.DynamoDB.DocumentClient({maxRetries: 15, retryDelayOptions: {base: 200}});
const args = process.argv.slice(2)
const table = args[0];
const inputfile = args[1];
console.debug('Arguments: ', args)

//Set the AWS profile if needed
if (args.length > 2 && args[2]) {
    console.debug("Setting up AWS profile to ", args[2]);
    const credentials = new AWS.SharedIniFileCredentials({profile: args[2]});
    AWS.config.credentials = credentials;
}

async function run()
{
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
