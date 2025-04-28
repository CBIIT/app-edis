const {conf} = require("./conf");
const axios = require("axios");
const {OrgListResponse, Organization} = require("./orgListResponse");
const {DataListResponse} = require("./dataListResponse");

async function getAuthorizationHeader(auth_type, auth_token, client_id, client_secret, get_token_url) {
    if (auth_type != 'prod') {
        return 'Bearer ' + auth_token;
    }

    // Get Auth2 token implementation
    const data = {
        grant_type: 'client_credentials',
        client_id: client_id,
        client_secret: client_secret
    };
    const resp = await axios.post(get_token_url, data, {
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
        }
    });
    console.debug('Token response', resp.data);
    return 'Bearer ' + resp.data['access_token'];
}

function processPaginatedResult(response, items) {
    const result = new DataListResponse();
    result.count = response.data.length;
    if (response.nextPageToken) {
        result.lastEvaluatedKey = response.nextPageToken;
    }
    result.items = items;
    return result;
}

function convertParametersToJson(data, prefix) {
    const result = {};
    data.forEach((p) => {
        let paths = p.Name.slice(prefix.length).split('/');
        let tempResult = result;
        for (let i = 0; i < paths.length - 1; i++) {
            if (typeof tempResult[paths[i]] === 'undefined') {
                tempResult[paths[i]] = {};
            }
            tempResult = tempResult[paths[i]];
        }
        tempResult[paths[paths.length - 1]] = p.Value;
    });
    console.debug('Parameters:', result);
    return result;
}


module.exports = { getAuthorizationHeader, processPaginatedResult, convertParametersToJson };
