'use strict';

const AWS = require('aws-sdk'),
    region = 'us-east-1';

AWS.config.update({ region: region });
const SECRET = process.env.SECRET || 'era-commons-connect';

// Create a Secrets Manager client
const client = new AWS.SecretsManager({
    region: region
});

async function getSecretParameters() {
    const data = await client.getSecretValue({SecretId: SECRET}).promise();
    if (data) {
        if (data['SecretString']) {
            const conf = JSON.parse(data.SecretString);
            return Promise.resolve(conf);
        }
    }
    else {
        console.error('SecretsManager: NO ERR OR DATA in response');
        return Promise.reject('SecretsManager: NO ERR OR DATA in response');
    }
}

module.exports = { getSecretParameters };
