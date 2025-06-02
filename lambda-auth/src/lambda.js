'use strict';

const OktaJwtVerifier = require('@okta/jwt-verifier');
const {conf, initConfiguration, initAuthConfiguration} = require("./conf");
const { getSecretParameters } = require('./secrets');
const { getConfigurationParameters } = require('./parameterstore');
const { authLdap } = require("./ldap-auth");

const oktaJwtVerifier = (process.env.ISSUER && process.env.AUDIENCE) ?
    new OktaJwtVerifier({
    issuer: process.env.ISSUER
}) : undefined;

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel == 'debug') {
    console.trace = function () {}
}
else if (logLevel && logLevel == 'info') {
    console.trace = function () {}
    console.debug = function () {}
}

const PARAMETER_PATH = process.env.PARAMETER_PATH || '/dev/app/eadis/auth/';

module.exports.handler = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false
    console.debug(JSON.stringify(event));
    const token = event.authorizationToken;
    console.debug('Authorization token :', token);

    if (token) {
        // Get authorization parameters from Parameter Store
        const authParameters = await getConfigurationParameters(PARAMETER_PATH);
        initAuthConfiguration(authParameters);

        // Basic Authentication with NIH Service Account
        if (token.indexOf('Basic') != -1) {
            console.debug('Analysis of Basic Authorization token');
            const base64credentials = token.split(' ')[1];
            console.debug('Base 64 credentials are ', base64credentials);
            const credentials = Buffer.from(base64credentials, 'base64').toString('ascii');
            console.debug('Ascii credentials are ', credentials);
            const [username, password] = credentials.split(':');
            console.debug('Basic Authentication for ', username);
            try {
                const configuration = await getSecretParameters();
                // Need to prepare private key here
                configuration.ad_cert = Buffer.from(configuration.ad_cert.replace(/\\n/g, '\n'), 'utf-8');
                initConfiguration(configuration);
                const cnUser = `cn=${username},${conf.ad.serviceAccountsBase}`;
                await authLdap(cnUser, password);
                console.info('Successful Basic Authentication for ', username);
            } catch (e) {
                console.error('Basic Authentication Error', e);
                return callback(null, generatePolicy('user', 'Deny', event['methodArn']));
            }
            return callback(null, generatePolicy('user', 'Allow', event['methodArn'], username));
        }
        // OAuth2 authentication
        else if (token.indexOf('Bearer') != -1) {
            console.debug('Analysis of Bearer Authorization token');
            const bearer_token = token.split(' ')[1];
            if (oktaJwtVerifier) {
                try {
                    const jwt = await oktaJwtVerifier.verifyAccessToken(bearer_token, process.env.AUDIENCE);
                    console.debug('OktaJwtVerifier verification:', jwt);
                    const username = (jwt.claims) ? jwt.claims.sub : undefined;
                    console.info('Successful Auth2 Token Authentication for ', username);
                    return callback(null, generatePolicy('user', 'Allow', event['methodArn'], username));

                } catch (err) {
                    console.error('OktaJwtVerifier verifyToken is failed:', err);
                    return callback(null, generatePolicy('user', 'Deny', event['methodArn']));
                }
            }
            else {
                console.error('OktaJwtVerifier is not defined - check your environment variables: ISSUER and AUDIENCE');
                return callback(null, generatePolicy('user', 'Deny', event['methodArn']));
            }

        }
    }
    return callback(null, generatePolicy('user', 'Deny', event['methodArn']));
}

function generatePolicy(user, effect, methodArn, username) {
    const authResponse = {};

    authResponse.principalId = user;
    if (effect && methodArn) {
        const firstSlash = methodArn.indexOf('/');
        const secondSlash = methodArn.indexOf('/', firstSlash + 1); // "arn:aws:execute-api:us-east-1:<acct id>:<api id>/"
        const resourcePrefix = methodArn.substring(0, secondSlash + 1); // "arn:aws:execute-api:us-east-1:<acct id>:<api id>/<stage>/
        const policyDocument = {};
        policyDocument.Version = '2012-10-17';
        policyDocument.Statement = [];
        if ((effect == "Allow") && username && conf.auth.users && conf.auth.users[username] && conf.auth.users[username].policies) {
            if (conf.auth.users[username].policies.allow) {
                const statement = {};
                statement.Action = 'execute-api:Invoke';
                statement.Effect = "Allow";
                const policies = conf.auth.users[username].policies.allow.split(',');
                statement.Resource = [];
                policies.forEach((policy) => statement.Resource.push(resourcePrefix + policy));
                policyDocument.Statement.push(statement);
            }
            if (conf.auth.users[username].policies.deny) {
                const statement = {};
                statement.Action = 'execute-api:Invoke';
                statement.Effect = "Deny";
                const policies = conf.auth.users[username].policies.deny.split(',');
                statement.Resource = [];
                policies.forEach((policy) => statement.Resource.push(resourcePrefix + policy));
                policyDocument.Statement.push(statement);
            }
        }
        else {
            const statementOne = {};
            statementOne.Action = 'execute-api:Invoke';
            statementOne.Effect = effect;
            statementOne.Resource = resourcePrefix + '*';
            policyDocument.Statement.push(statementOne);
        }
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


