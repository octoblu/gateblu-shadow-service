request = require 'request'

class ShadowService
  constructor: ({@shadowServiceUri}) ->

  proxy: ({meshbluAuth,body}, callback) =>
    options =
      baseUrl: @shadowServiceUri
      uri: '/config'
      auth:
        username: meshbluAuth.uuid
        password: meshbluAuth.token
      json: body

    request.post options, (error, response) =>
      return callback null, @_gatewayErrorResponse() if error?
      callback null, response, body

  _gatewayErrorResponse: =>
    statusCode: 502
    body: 'Could not contact the shadow service'

module.exports = ShadowService
