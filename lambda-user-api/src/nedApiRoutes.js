'use strict'

const soap = require('soap');
const WSSecurity = require('wssecurity');
const {conf} = require("./conf");
const isNum = new RegExp('^[0-9]+$');

let wsSecurity_v7;        // Soap security
let soapClient;           // Soap Client for GET By endpoints
let soapClientForChanges; // Soap Client for NED Changes


function nedRoutes(app, opts) {

    // We use post instead of get to allow to pass characters like apostrophe, which NIH network does not allow in URL string
    app.post('/userByName', async (req, res) => {
        console.info('/userapi/ned/userByName', req.body);
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
    app.get('/userByNIHid/:id', async (req, res) => {
        console.info('/userapi/ned/userByNIHid', req.params);
        try {
            const nihId = req.params.id;

            if (nihId === undefined) {
                res.status(400).send('nihid is not defined.');
            }
            else if (!isNum.test(nihId)) {
                res.status(400).send('nihid is not numeric.');
            }
            else if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                res.json({ 'Success': true});
            }
            else {
                res.json(await getByNIHid(nihId));
            }
        } catch (error) {
            res.status(500).send(error);
        }
    });
    app.get('/userByIDAccount/:id', async (req, res) => {
        console.info('/userapi/ned/userByIDAccount', req.params);
        try {
            if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            res.json(await getByADAccount(req.params.id));
        } catch (error) {
            res.status(500).send(error);
        }
    });
    app.get('/usersByIc/:ic', async (req, res) => {
        console.info('/userapi/ned/usersByIc', req.params);
        try {
            if (req.query.Testing) {
                console.info(`Return in Testing mode`);
                return { 'Success': true};
            }
            res.json(await getByIc(req.params.ic, req.query.idOnly | false));
        } catch (error) {
            res.status(500).send(error);
        }
    });
    app.get('/changesByIc/:ic', async (req, res) => {
        console.info('/userapi/ned/changesByIc', req.params);
        try {
            if (req.query.Testing) {
                console.info(`Return in Testing mode - no actual call is performed`);
                return { 'Success': true};
            }
            res.json(await getChangesByIc(req.params.ic,
                req.query.From_Date, req.query.From_Time, req.query.To_Date, req.query.To_Time));
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

async function getByNIHidMultiple(nihids) {
    console.info(`Getting multiple NED users by NIH ID (${nihids.length} ids`);
    const args = {
        NIHID: nihids
    };
    console.debug(`Continue in real mode `, args);
    const client = await _getSoapClient();
    const result = await client.ByNIHidMultipleAsync(args);
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

async function getByIc(ic, idOnly) {
    console.info(`Getting NED users by IC`, ic);
    const args = {
        IC_or_SAC: ic,
        ReturnNIHIDOnly: idOnly | false
    };
    console.debug(`Continue in real mode `, args);
    const client = await _getSoapClient();
    const result = await client.ByICAsync(args);
    return (Array.isArray(result) && result.length > 0) ? result[0] : result;
}

async function getByIcPaginated(ic) {
    console.info(`Getting NED users by IC`, ic);
    const args = {
        IC_or_SAC: ic,
        ReturnNIHIDOnly: true
    };
    console.debug(`Continue in real mode `);
    const client = await _getSoapClient();
    const result0 = await client.ByICAsync(args);
    const part1 = [];
    const max = Math.min(1000, result0[0].NumberOfRecords);
    console.debug(`Returned ${result0[0].NumberOfRecords} record ids, will retrieve ${max} records`);
    for (let i=0; i < max; i++) {
        // part1.push({ NIHID: result0[0].NEDPerson[i].Uniqueidentifier });
        part1.push(result0[0].NEDPerson[i].Uniqueidentifier);
    }
    console.debug('Call get by NIH Id multiple...');
    const result = await getByNIHidMultiple(part1);
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
        console.debug('About to get soap client', conf.ned.wsdl)
        soapClient = await soap.createClientAsync(conf.ned.wsdl);
        soapClient.setSecurity(_getWsSecurity_v7());
        console.debug('Soap client has been created', conf.ned.wsdl)
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

module.exports = {nedRoutes, getByName, getByNIHid, getByIc, getByIcPaginated}