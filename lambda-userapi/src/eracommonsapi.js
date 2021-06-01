'use strict'

module.exports = (app, opts) => {

    app.get('/users', (req, res) => {
        const result = {
            "total": 1,
            "offset": 0,
            "size": 1,
            "data": [{
                "ACCOUNT_CREATED_DATE": "2000-01-23T04:56:07.000+00:00",
                "ORG_ID": 5,
                "ORG_NAME": "ORG_NAME",
                "ACCOUNT_UPDATED_DATE": "2000-01-23T04:56:07.000+00:00",
                "USER_ID": "USER_ID",
                "NAME_PREFFIX": "NAME_PREFFIX",
                "STATUS_CODE": 5,
                "EMAIL": "EMAIL",
                "LAST_NAME": "LAST_NAME",
                "FIRST_NAME": "FIRST_NAME",
                "STATUS_DESC": "STATUS_DESC",
                "MI_NAME": "MI_NAME",
                "NAME_SUFFIX": "NAME_SUFFIX"
            }]
        }
        res.json(result);
    })

    app.get('/user/:userid', (req, res) => {
        const userid = req.params.userid;

        const result = {
            "ACCOUNT_CREATED_DATE" : "2000-01-23T04:56:07.000+00:00",
            "ORG_ID" : 5,
            "ORG_NAME" : "ORG_NAME",
            "ACCOUNT_UPDATED_DATE" : "2000-01-23T04:56:07.000+00:00",
            "USER_ID" : userid,
            "NAME_PREFFIX" : "NAME_PREFFIX",
            "STATUS_CODE" : 5,
            "EMAIL" : "EMAIL",
            "LAST_NAME" : "LAST_NAME",
            "FIRST_NAME" : "FIRST_NAME",
            "STATUS_DESC" : "STATUS_DESC",
            "MI_NAME" : "MI_NAME",
            "NAME_SUFFIX" : "NAME_SUFFIX"
        };
        res.json(result);
    })
}