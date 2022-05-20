'use strict'

const AWSXRay = require('aws-xray-sdk-core')
const soap = require('soap');
const WSSecurity = require('wssecurity');
const {conf} = require("./conf");
const isNum = new RegExp('^[0-9]+$');

const AWS = AWSXRay.captureAWS(require('aws-sdk'))
AWS.config.update({ region: "us-east-1"});

let wsSecurity_v7;        // Soap security
let soapClient;           // Soap Client for GET By endpoints
let soapClientForChanges; // Soap Client for NED Changes


function nedRoutes(app, opts) {

    app.post('/ByName', async (req, res) => {
        try {
            if (req.body.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            res.json(await getByName(req.body.FirstName, req.body.LastName));
        } catch (error) {
            res.status(500).send(error);
        }
    });
    app.post('/ByNIHid', async (req, res) => {
        try {
            const nihId = req.body.nihid;

            if (nihId === undefined) {
                res.status(400).send('nihid is not defined.');
            }
            else if (!isNum.test(nihId)) {
                res.status(400).send('nihid is not numeric.');
            }
            else if (req.body.Testing) {
                console.info(`Return in Testing mode`);
                res.json({ 'Success': true});
            }
            else {
                res.json(await getByNIHid(nihid));
            }
        } catch (error) {
            res.status(500).send(error);
        }
    });
    app.post('/ByIDAccount', async (req, res) => {
        try {
            if (req.body.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            res.json(await getByADAccount(req.body.Identifier));
        } catch (error) {
            res.status(500).send(error);
        }
    });
    app.post('/ByIc', async (req, res) => {
        try {
            if (req.body.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            res.json(await getByIc(req.body.IcoreSite));
        } catch (error) {
            res.status(500).send(error);
        }
    });
    app.post('/changesByIc', async (req, res) => {
        try {
            if (req.body.Testing) {
                console.info(`Return in Testing mode - no actual call is performed`);
                return { 'Success': true};
            }
            res.json(await getChangesByIc(req.body.IcoreSite,
                req.body.From_Date, req.body.From_Time, req.body.To_Date, req.body.To_Time));
        } catch (error) {
            res.status(500).send(error);
        }
    });
}

async function getByName(firstName, lastName) {
    console.info(`Getting NED user by name`, firstName, lastName);
    const args = {
        FirstName: firstName || '',
        LastName: lastName || ''
    };

    console.debug(`Continue in real mode 1 `, conf.ned.wsdl);
    console.debug(`Continue in real mode 2 `, args);
    const client = await _getSoapClient();
    // console.debug(`Got soap client `, client);
    const result = await client.ByNameAsync(args);
    console.debug(`Got result `);
    
    return (Array.isArray(result) && result.length > 0) ? result[0] : result;
}

async function getByNIHid(nihid) {
    console.info(`Getting NED user by NIH ID`, nihid);
    const args = {
        NIHID: nihid
    };
    console.debug(`Continue in real mode `, args);
    const client = await _getSoapClient();
    const result = await client.ByNIHIdAsync(args);
    return (Array.isArray(result) && result.length > 0) ? result[0] : result;
}

async function getByADAccount(idAccount) {
    console.info(`Getting NED user by ID Account`, idAccount);
    const args = {
        Identifier: idAccount
    };
    console.debug(`Continue in real mode `, args);
    const client = await _getSoapClient();
    const result = await client.ByADAccountAsync(args);
    return (Array.isArray(result) && result.length > 0) ? result[0] : result;
}

async function getByIc(ic) {
    console.info(`Getting NED users by IC`, ic);
    const args = {
        IC_or_SAC: ic,
        ReturnNIHIDOnly: true
    };
    console.debug(`Continue in real mode `, args);
    const client = await _getSoapClient();
    const result = await client.ByICAsync(args);
    return (Array.isArray(result) && result.length > 0) ? result[0] : result;
}

async function getChangesByIc(ic, fromDate, fromTime, toDate, toTime) {
    console.info(`Getting NED changes by IC`, ic, fromDate, fromTime, toDate, toTime);
    const args = {
        ICorSITE: ic,
        From_Date: fromDate,
    };
    if (fromTime) {
        args.From_time = fromTime;
    }
    if (toDate) {
        args.To_Date = toDate;
    }
    if (toTime) {
        args.To_time = toTime;
    }
    console.debug(`Continue in real mode `, args);
    const client = await _getSoapClientForChanges();
    const result = await client.ByICAsync(args);
    return (Array.isArray(result) && result.length > 0) ? result[0] : result;
}

/**
 * Internal functions to retrieve WS endpoints 
 */

async function _getSoapClient() {
    if (!soapClient) {
        soapClient = await soap.createClientAsync(conf.ned.wsdl);
        soapClient.setSecurity(_getWsSecurity_v7());
    }
    return soapClient;
}
async function _getSoapClientForChanges() {
    if (!soapClientForChanges) {
        soapClientForChanges = await soap.createClientAsync(conf.ned.wsdl_changes);
        soapClientForChanges.setSecurity(_getWsSecurity_v7());
    }
    return soapClientForChanges;
}
function _getWsSecurity_v7() {
    if (!wsSecurity_v7) {
        wsSecurity_v7 = new WSSecurity(conf.ned.user, conf.ned.pwd);
    }
    return wsSecurity_v7
}

module.exports = {nedRoutes, getByName}