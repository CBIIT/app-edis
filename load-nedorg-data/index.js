var AWS = require("aws-sdk");
var fs = require('fs');

AWS.config.update({
   region: "us-east-1"
});

const docClient = new AWS.DynamoDB.DocumentClient();
const table = process.argv.slice(2)[0];

console.log("Importing data into DynamoDb table \"" + table + "\"");

const allRecs = JSON.parse(fs.readFileSync('nci_orgs_orig.json', 'utf-8'));
let n = 0;
allRecs.forEach(function (rec) {
   var params = {
       TableName: table,
       Item: rec
   };
   console.log(JSON.stringify(params));

   docClient.put(params, function (err, data) {
       if (err) {
           console.error(JSON.stringify(err));
       }
   })
   n++;
});

console.log("Imported " + n + " data records into DynamoDb table \"nedorgs\"");
// process.exit();
setTimeout(function () {
    process.exit();
}, 10000);
