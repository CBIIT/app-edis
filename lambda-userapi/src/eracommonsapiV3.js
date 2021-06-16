'use strict'

const AWSXRay = require('aws-xray-sdk-core')
const { DynamoDBClient, QueryCommand, ScanCommand, GetItemCommand } = require("@aws-sdk/client-dynamodb");
const ddb = AWSXRay.captureAWSv3Client(new DynamoDBClient({region: "us-east-1"}))

const userTable = 'extusers-dev'

function stringFromDate(todaysDate) {
    const yyyy = todaysDate.getFullYear().toString();
    const mm = todaysDate.getMonth()+1
    const dd  = todaysDate.getDate();
    return (yyyy + '-' + (mm < 10 ? '0' + mm : mm ) + '-' + (dd < 10 ? '0' + dd : dd));
}

function dateFromString(strFrom) {
    const dateParts = strFrom.split('-');
    return new Date(+dateParts[0], +dateParts[1] - 1, +dateParts[2])
}

module.exports = (app, opts) => {

    app.get('/users', async (req, res) => {
        let strFrom = req.query.from;
        let strTo   = req.query.to;
        let byScan = req.query.scan;

        console.debug('Get Users: ', strFrom, strTo, byScan)

        if (strFrom && !byScan) {
            let dateFrom = dateFromString(strFrom);
            if (!strTo) {
                strTo = stringFromDate(new Date());
            }
            console.debug('GetUsers from - to', strFrom, strTo);

            const params = {
                TableName: userTable,
                IndexName: 'dateIndex',
                KeyConditionExpression: "#attr = :date",
                ExpressionAttributeNames: {
                    "#attr": "LAST_UPDATED_DAY"
                }
            }

            const result = {
                count: 0,
                items: []
            }

            console.log('GetUsers by query from - to', strFrom, strTo);
            let strDate = strFrom;

            while (strDate <= strTo) {
                params.ExpressionAttributeValues = {
                    ":date": strDate
                }
                try {
                    do {
                        const cmd = new QueryCommand(params);
                        const data = await ddb.send(cmd);
                        if (data && data.Items) {
                            console.debug('Query getUsers on date ' + strDate + ' - result: ', data.Items.length)
                            result.items = result.items.concat(data.Items);
                            result.count += data.Items.length
                        }
                        params.ExclusiveStartKey = data.LastEvaluatedKey;
                    } while (params.ExclusiveStartKey);
                } catch (err) {
                    result.items = [];
                    result.error = JSON.stringify(err);
                    break;
                }
                // next date
                console.debug('Current Date:', dateFrom.getFullYear(), dateFrom.getMonth(), dateFrom.getDate());
                let nextDate = +dateFrom.getDate() + 1;
                dateFrom.setDate(nextDate);
                console.debug('Next Current Date:', nextDate, dateFrom.getFullYear(), dateFrom.getMonth(), dateFrom.getDate());
                strDate = stringFromDate(dateFrom);
                console.debug('Next Date:', nextDate, strDate);
            }

            if (result.error) {
                console.log('GetUsers by query from ' + strFrom + ' to ' + strTo + ' returns error:', result.error);
            }
            else {
                console.log('GetUsers by query from ' + strFrom + ' to ' + strTo + ' returns ' + result.count + ' items');
            }
            res.json(result);
        }
        else {
            //******  Using scan *****//
            console.log('GetUsers by scan from - to', strFrom, strTo);

            const params = {
                TableName: userTable
            }

            if (strFrom) {
                if (!strTo) {
                    strTo = stringFromDate(new Date());
                }

                params.FilterExpression = 'LAST_UPDATED_DAY BETWEEN :start AND :end'
                params.ExpressionAttributeValues = {
                    ':start': strFrom,
                    ':end': strTo
                }
            }
            console.debug("Get users by scan", strFrom, strTo, params)
            let result = {
                count: 0,
                items: []
            }
            try {
                do {
                    const cmd = new ScanCommand(params);
                    const data = await ddb.send(cmd);
                    console.debug("Get users by scan results:", data)
                    result.count += data.Items.length;
                    result.items = result.items.concat(data.Items);
                    params.ExclusiveStartKey = data.LastEvaluatedKey;
                } while (params.ExclusiveStartKey);
                console.log('GetUsers by scan from ' + strFrom + ' to ' + strTo + ' returns ' + result.count + ' items');
            } catch (err) {
                result.items = [];
                result.error = err;
                console.log('GetUsers by scan from ' + strFrom + ' to ' + strTo + ' returns error:', result.error);
            }
            res.json(result);
        }
    });

    app.get('/users/date/:date', async (req, res) => {
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
                ":date": { "S": given_date }
            }
        }
        const result = {
            count: 0,
            items: []
        }

        try {
            do {
                const cmd = new QueryCommand(params);
                const data = await ddb.send(cmd);
                if (data && data.Items) {
                    result.count += data.Items.length;
                    result.items = result.items.concat(data.Items);
                }
                params.ExclusiveStartKey = data.LastEvaluatedKey;
            } while (params.ExclusiveStartKey);
            console.debug('Query by date - result: ', result)
            console.log('get users for ' + given_date + ' returns ' + result.count + ' items');
        } catch (err) {
            result.error = err;
            console.log('get users for ' + given_date + ' returns error:', result.error);
        }
        res.json(result);
    })

    app.get('/user/:userid', (req, res) => {
        const userid = req.params.userid;

        console.log('get extuser for USER_ID = ' + userid);
        // req.log.debug('through logging frmwrk - get extuser for USER_ID ' + userid);

        const params = {
            TableName: userTable,
            Key: {
                USER_ID: userid
            }
        }
        const cmd = new GetItemCommand(params);
        ddb.send(cmd, (err, data) => {
            if (err) {
                const errJson = JSON.stringify(err)
                console.error('get extuser for USER_ID = ' + userid + ' returns error:', err);
                res.json({ error: errJson});
            } else {
                res.json(data.Item)
            }
        });
    })
}