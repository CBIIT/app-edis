'use strict'

const app = require('lambda-api')({version: 'v1.0', base: 'orgapi/v1', logger: {level: 'debug'}})
const AWS = require('aws-sdk')

const version = '0.0.6'

AWS.config.update({ region: "us-east-1"});
const ddb = new AWS.DynamoDB.DocumentClient();
const nedTable = 'nedorgs-dev'


app.get('/nedorgs/:sac/children', (req, res) => {
    const sac = req.params.sac;

    const params = {
        TableName: nedTable,
        KeyConditionExpression: "#ps = :psv",
        ExpressionAttributeNames: {
            "#ps": "parent_sac"
        },
        ExpressionAttributeValues: {
            ":psv": sac
        }
    }

    ddb.query(params, (err, data) => {
        if (err) {
            console.error(JSON.stringify(err));
            res.send(err)
        }
        else {
            res.json(data);
        }
    });
})

app.get('/nedorgs/:sac', (req, res) => {
    const sac = req.params.sac;
    console.log('get nedorgs for ' + sac + ' version=' + version);
    req.log.debug('through logging frmwrk - get nedorgs for ' + sac + ' version=' + version);

    const params = {
        TableName: nedTable,
        IndexName: 'sacIndex',
        KeyConditionExpression: "#ps = :psv",
        ExpressionAttributeNames: {
            "#ps": "sac"
        },
        ExpressionAttributeValues: {
            ":psv": sac
        }
    }
    ddb.query(params, (err, data) => {
        if (err) {
            const errJson = JSON.stringify(err)
            console.error(errJson);
            res.send(err)
        }
        else {
            if (data && Array.isArray(data.Items)) {
                if (data.Items.length) {
                    res.json({ Item: data.Items[0], Version: version })
                }
                else {
                    res.json({ error: "Object '" + sac + "' not found"})
                }
            }
            else {
                data.Version = version
                res.json(data)
            }
        }
    });
})

app.get('/nedorgs/:term/startwith', (req, res) => {
    const term = req.params.term;

    const params = {
        TableName: nedTable,
        FilterExpression: "begins_with(#sac, :term)",
        ExpressionAttributeNames: {
            "#sac": "sac"
        },
        ExpressionAttributeValues: {
            ":term": term
        }
    }

    ddb.scan(params, (err, data) => {
        if (err) {
            console.error(JSON.stringify(err));
            res.send(err)
        }
        else {
            res.json(data);
        }
    });
})

module.exports = app
