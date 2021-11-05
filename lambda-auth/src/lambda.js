const OktaJwtVerifier = require('@okta/jwt-verifier');

const oktaJwtVerifier = (process.env.ISSUER && process.env.AUDIENCE) ?
    new OktaJwtVerifier({
    issuer: process.env.ISSUER
}) : undefined;

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel == 'info') {
    console.debug = function () {}
}

module.exports.handler = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false
    console.debug(JSON.stringify(event));
    const token = event.authorizationToken;
    console.debug('Authorization token :', token);

    if (token) {
        if (token.indexOf('Basic') != -1) {
            console.debug('Analysis of Basic Authorization token');
            const base64credentials = token.split(' ')[1];
            console.debug('Base 64 credentials are ', base64credentials);
            const credentials = Buffer.from(base64credentials, 'base64').toString('ascii');
            console.debug('Ascii credentials are ', credentials);
            const [username, password] = credentials.split(':');
            console.debug('Basic Authentication', username, password);
            return callback(null, generatePolicy('user', 'Allow', event.methodArn));
        }
        else if (token.indexOf('Bearer') != -1) {
            console.debug('Analysis of Bearer Authorization token');
            const bearer_token = token.split(' ')[1];
            if (oktaJwtVerifier) {
                try {
                    const jwt = await oktaJwtVerifier.verifyAccessToken(bearer_token, process.env.AUDIENCE);
                    console.debug('OktaJwtVerifier verification:', jwt);
                    return callback(null, generatePolicy('user', 'Allow', event.methodArn));

                } catch (err) {
                    console.error('OktaJwtVerifier verifyToken is failed:', err);
                    return callback(null, generatePolicy('user', 'Deny', event.methodArn));
                }
            }
            else {
                console.error('OktaJwtVerifier is not defined - check your environment variables: ISSUER and AUDIENCE');
                return callback(null, generatePolicy('user', 'Deny', event.methodArn));
            }

        }
    }
    var tmp = str.replace('"', '\"');
    return callback(null, generatePolicy('user', 'Allow', event.methodArn));
}

function generatePolicy(user, effect, methodArn, username) {
    const authResponse = {};

    authResponse.principalId = user;
    if (effect && methodArn) {
        const policyDocument = {};
        policyDocument.Version = '2012-10-17';
        policyDocument.Statement = [];
        const statementOne = {};
        statementOne.Action = 'execute-api:Invoke';
        statementOne.Effect = effect;
        statementOne.Resource = methodArn.substring(0, methodArn.indexOf('/')) + '/*';
        policyDocument.Statement[0] = statementOne;
        authResponse.policyDocument = policyDocument;
    }

    // Optional output with custom properties
    authResponse.context = {
        "userID": username
    };

    // Assign a usage identifier API Key if it's needed
    // authResponse.usageIdentifierKey = "1C3uCXWZSQ8CJL2AbKyfY8B7sgekeI9F*****";
    console.debug('Return policy : ', JSON.stringify(authResponse));
    return authResponse;
}


