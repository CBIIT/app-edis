'use strict'

const AWS = require('aws-sdk')

const version = '0.0.6'

AWS.config.update({ region: "us-east-1"});
const ddb = new AWS.DynamoDB.DocumentClient();
const nedTable = 'nedorgs-dev'


module.exports = (app, opts) => {

    app.get('/org/:sac/children', (req, res) => {
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
            } else {
                res.json(data);
            }
        });
    })

    app.get('/org/:sac', (req, res) => {
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
            } else {
                if (data && Array.isArray(data.Items)) {
                    if (data.Items.length) {
                        res.json({Item: data.Items[0], Version: version})
                    } else {
                        res.json({error: "Object '" + sac + "' not found"})
                    }
                } else {
                    data.Version = version
                    res.json(data)
                }
            }
        });
    })

}
