'use strict';

const AWS = require('aws-sdk'),
    region = 'us-east-1';

AWS.config.update({ region: region });
// Create a Secrets Manager client
const client = new AWS.SSM();

async function getConfigurationParameters(path) {
    let data = [];
    let resp = {};
    do {
        let params = {
            Path: path,
            Recursive: true,
            WithDecryption: true
        }
        if (resp.NextToken) {
            params.NextToken = resp.NextToken;
        }
        resp = await client.getParametersByPath(params).promise();
        data = data.concat(resp.Parameters);
    } while (resp.NextToken !== undefined);
    return convertParametersToJson(data, path);
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

module.exports = { getConfigurationParameters };
