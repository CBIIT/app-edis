const soap = require ('soap');
const WSSecurity = require ('wssecurity');
const { conf } = require ('./conf');

let soapClient;
let wsSecurity_v7;

/**
 * Internal functions to retrieve WS endpoints
 */

async function _getSoapClient() {
    if (!soapClient) {
        console.debug('About to get soap client', conf.fred.wsdl)
        soapClient = await soap.createClientAsync(conf.fred.wsdl);
        soapClient.setSecurity(_getWsSecurity_v7());
        console.debug('Soap client has been created', conf.fred.wsdl)
    }
    return soapClient;
}

function _getWsSecurity_v7() {
    if (!wsSecurity_v7) {
        wsSecurity_v7 = new WSSecurity(conf.fred.user, conf.fred.pwd);
    }
    return wsSecurity_v7
}

async function getAllProperties(){
    console.info(`Getting Frederick Properties`);
    const client = await _getSoapClient();
    // console.debug(`Got soap client `, client);
    const result = await client.GetAllPropertyAsync();

    console.debug('Got the result ');

    return (Array.isArray(result) && result.length > 0) ? result[0] : result;
}

module.exports = {getAllProperties}
