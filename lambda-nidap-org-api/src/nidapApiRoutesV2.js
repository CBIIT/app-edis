const {conf} = require("./conf");
const {getAuthorizationHeader, processPaginatedResult} = require("./util");
const axios = require("axios");

function nidapApiRoutesV2(app, opts) {
    app.get('/:dataObject', async (req, res) => {
        console.info(opts.prefix + '/' + req.params['dataObject']);
        try {
            if (req.query['Testing']) {
                console.info(`Return in Testing mode`);
                res.json({ 'Success': true});
            }
            res.json(await listAllData(req.params['dataObject'], req.query.lastEvaluatedKey));
        } catch (error) {
            console.error('ERROR:', error);
            res.status(500).send(error);
        }
    });
    app.get('/:dataObject/:primary', async (req, res) => {
        console.info(`${opts.prefix} / ${req.params['dataObject']} / ${req.params['primary']}`);
        try {
            if (req.query['Testing']) {
                console.info(`Return in Testing mode`);
                res.json({ 'Success': true});
            }
            res.json(await searchDataByPrimaryKey(req.params['dataObject'], req.params['primary']));
        } catch (error) {
            console.error('ERROR:', error);
            res.status(500).send(error);
        }
    });
}

async function listAllData(dataType, lastEvaluatedKey) {
    console.debug(`List All ${dataType} from NIDAP`);
    confData = conf.nidap.api[dataType];
    if ('undefined' === typeof confData) {
        throw new Error('The object type ' + dataType + ' is not configured')
    }
    const ontology = confData['ontology'] || conf.nidap.default_ontology;
    let queryParameters = (confData['orderBy']) ? '?orderBy=' + confData['orderBy'] : '';
    if (lastEvaluatedKey) {
        queryParameters += ((queryParameters.length > 0) ? '&' : '?') + `pageToken=${lastEvaluatedKey}`;
    }
    const objectType = confData['ontology_object_type'];
    let url = `${conf.nidap.url_v2}${ontology}/objects/${objectType}${queryParameters}`;
    console.info(`URL: ${url}`);
    const auth = await getAuthorizationHeader(conf.nidap.auth_type, conf.nidap.auth_token, conf.nidap.auth_client_id,
        conf.nidap.auth_client_secret, conf.nidap.url_token);
    const resp = await axios.get(url, {
        headers: {
            'Authorization': auth
        }
    });
    const items = [];
    let propertiesMap = convertPropertiesToMap(confData['propertiesMap']);
    console.info(propertiesMap);
    resp.data.data.forEach((r) => {
        items.push(migrateProperties(r, propertiesMap));
    });
    const result = processPaginatedResult(resp.data, items);
    console.info(`listAllData completed.  Returns ${result.items.length} items`);
    return result;
}

async function searchDataByPrimaryKey(dataType, primaryKey) {
    console.debug(`Search ${dataType} from NIDAP by ${primaryKey}`);
    confData = conf.nidap.api[dataType];
    if ('undefined' === typeof confData) {
        throw new Error('The object type ' + dataType + ' is not configured')
    }
    const ontology = confData['ontology'] || conf.nidap.default_ontology;
    const objectType = confData['ontology_object_type'];
    let url = `${conf.nidap.url_v2}${ontology}/objects/${objectType}/${primaryKey}`;
    console.info(`URL: ${url}`);
    const auth = await getAuthorizationHeader(conf.nidap.auth_type, conf.nidap.auth_token, conf.nidap.auth_client_id,
        conf.nidap.auth_client_secret, conf.nidap.url_token);
    const resp = await axios.get(url, {
        headers: {
            'Authorization': auth
        }
    });
    let propertiesMap = convertPropertiesToMap(confData['propertiesMap']);
    return migrateProperties(resp.data, propertiesMap);
}

// Convert comma separated key=value string to map
function convertPropertiesToMap(sMap) {
    if (sMap === undefined || sMap === null) {
        return null;
    }
    let map = {};
    sMap.split(",").forEach(function(keyValue) {
       let pair = keyValue.split("=");
       map[pair[0]] = pair[1];
    });
    return map;
}

function migrateProperties(r, map) {
    if (map === undefined || map === null) {
        return r;
    }
    const ret = {};
    for (const key in map) {
        if (r[map[key]]) {
            ret[key] = r[map[key]];
        }
    }
    return ret;
}

module.exports = { nidapApiRoutesV2, listAllData, searchDataByPrimaryKey };