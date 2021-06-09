const app = require('lambda-api')({version: 'v1.0', logger: {level: 'debug'}})

// Set the console log level
const logLevel = process.env['LOG_LEVEL'];
if (logLevel && logLevel == 'info') {
  console.debug = function () {}
}

// app.register(require('./restapi'), { prefix: '/nedorgapi/v1'})
app.register(require('./eracommonsapi'), { prefix: '/eracommonsapi/v1'})

module.exports.handler = (event, context, callback) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.debug(JSON.stringify(event));
  app.run(event, context, callback)
}
