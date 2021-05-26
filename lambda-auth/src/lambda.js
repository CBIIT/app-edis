
module.exports.handler = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false
    console.debug(JSON.stringify(event));
    const token = event.authorizationToken;
    console.debug('Authorization token :', token);

    if (token && token.indexOf('Basic') != -1) {
        console.debug('Analysis of Basic Authorization token');
        const base64credentials = token.split(' ')[1];
        console.debug('Base 64 credentials are ', base64credentials);
        const credentials = Buffer.from(base64credentials, 'base64').toString('ascii');
        console.debug('Ascii credentials are ', credentials);
        const [username, password] = credentials.split(':');
        console.debug('Basic Authentication', username, password);
    }
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
        statementOne.Resource = methodArn;
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


