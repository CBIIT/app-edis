const readme = require('./src/lambda')

async function runme()
{
    await readme.readFromEraCommons();
}

runme();