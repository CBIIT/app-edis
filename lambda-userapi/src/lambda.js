const app = require('./restapi')


module.exports.handler = (event, context, callback) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.debug(JSON.stringify(event));
  app.run(event, context, callback)
}
