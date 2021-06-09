'use strict'

const AWSXRay = require('aws-xray-sdk-core')
const AWS = AWSXRay.captureAWS(require('aws-sdk'))
AWS.config.update({ region: "us-east-1"});
const ddb = new AWS.DynamoDB.DocumentClient();
const userTable = 'extusers-dev'

module.exports = (app, opts) => {

    app.get('/users', (req, res) => {
        const fromDate = req.query.from;
        const toDate = req.query.to;

        const params = {
            TableName: userTable
        }

        if (fromDate && toDate) {
            params.FilterExpression = 'LAST_UPDATED_DAY BETWEEN :start AND :end'
            params.ExpressionAttributeValues = {
                ':start': fromDate,
                ':end': toDate
            }
        }

        ddb.scan(params, (err, data) => {
            if (err) {
                console.error(JSON.stringify(err));
                res.send(err)
            }
            else {
                const result = {}
                console.debug("Scan Results", data)
                result.total = data.Items.length;
                result.data = data.Items;
                res.json(result);
            }
        })

        // const result = {
        //     "total": 1,
        //     "offset": 0,
        //     "size": 1,
        //     "data": [{
        //         "ACCOUNT_CREATED_DATE": "2000-01-23T04:56:07.000+00:00",
        //         "ORG_ID": 5,
        //         "ORG_NAME": "ORG_NAME",
        //         "ACCOUNT_UPDATED_DATE": "2000-01-23T04:56:07.000+00:00",
        //         "USER_ID": "USER_ID",
        //         "NAME_PREFFIX": "NAME_PREFFIX",
        //         "STATUS_CODE": 5,
        //         "EMAIL": "EMAIL",
        //         "LAST_NAME": "LAST_NAME",
        //         "FIRST_NAME": "FIRST_NAME",
        //         "STATUS_DESC": "STATUS_DESC",
        //         "MI_NAME": "MI_NAME",
        //         "NAME_SUFFIX": "NAME_SUFFIX"
        //     }]
        // }
        // res.json(result);
    });

    app.get('/users/date/:date', (req, res) => {
        const given_date = req.params.date;

        console.log('get users for ' + given_date);
        // req.log.debug('through logging frmwrk - get users for ' + given_date);

        const params = {
            TableName: userTable,
            IndexName: 'dateIndex',
            KeyConditionExpression: "#attr = :date",
            ExpressionAttributeNames: {
                "#attr": "LAST_UPDATED_DAY"
            },
            ExpressionAttributeValues: {
                ":date": given_date
            }
        }
        ddb.query(params, (err, data) => {
            if (err) {
                console.error(JSON.stringify(err));
                res.send(err)
            } else {
                const result = {}
                result.total = data.length
                result.data = data
                console.debug('Query by date - result: ',result )
                res.json(result);
            }
        });
    //     const result = {
    //         "total": 1,
    //         "offset": 0,
    //         "size": 1,
    //         "data": [{
    //             "ACCOUNT_CREATED_DATE": "2000-01-23T04:56:07.000+00:00",
    //             "ORG_ID": 5,
    //             "ORG_NAME": "ORG_NAME",
    //             "ACCOUNT_UPDATED_DATE": "2000-01-23T04:56:07.000+00:00",
    //             "USER_ID": "USER_ID",
    //             "NAME_PREFFIX": "NAME_PREFFIX",
    //             "STATUS_CODE": 5,
    //             "EMAIL": "EMAIL",
    //             "LAST_NAME": "LAST_NAME",
    //             "FIRST_NAME": "FIRST_NAME",
    //             "STATUS_DESC": "STATUS_DESC",
    //             "MI_NAME": "MI_NAME",
    //             "NAME_SUFFIX": "NAME_SUFFIX"
    //         }]
    //     }
    //     res.json(result);
    })

    app.get('/user/:userid', (req, res) => {
        const userid = req.params.userid;

        console.log('get extuser for USER_ID = ' + userid);
        // req.log.debug('through logging frmwrk - get extuser for USER_ID ' + userid);

        const params = {
            TableName: userTable,
            KeyConditionExpression: "#attr = :user_id",
            ExpressionAttributeNames: {
                "#attr": "USER_ID"
            },
            ExpressionAttributeValues: {
                ":user_id": userid
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
                        res.json(data.Items[0])
                    } else {
                        res.json({error: "User '" + userid + "' not found"})
                    }
                } else {
                    res.json(data)
                }
            }
        });

        // const result = {
        //     "ACCOUNT_CREATED_DATE" : "2000-01-23T04:56:07.000+00:00",
        //     "ORG_ID" : 5,
        //     "ORG_NAME" : "ORG_NAME",
        //     "ACCOUNT_UPDATED_DATE" : "2000-01-23T04:56:07.000+00:00",
        //     "USER_ID" : userid,
        //     "NAME_PREFFIX" : "NAME_PREFFIX",
        //     "STATUS_CODE" : 5,
        //     "EMAIL" : "EMAIL",
        //     "LAST_NAME" : "LAST_NAME",
        //     "FIRST_NAME" : "FIRST_NAME",
        //     "STATUS_DESC" : "STATUS_DESC",
        //     "MI_NAME" : "MI_NAME",
        //     "NAME_SUFFIX" : "NAME_SUFFIX"
        // };
        // res.json(result);
    })
}