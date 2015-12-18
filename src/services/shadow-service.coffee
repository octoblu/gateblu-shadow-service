request = require 'request'

class ShadowService
  constructor: ({@shadowServiceUri}) ->

  proxy: ({meshbluAuth,body}, callback) =>
    options =
      baseUrl: @shadowServiceUri
      uri: '/virtual/config'
      auth:
        username: meshbluAuth.uuid
        password: meshbluAuth.token
      json: body

    request.post options, (error, response, body) =>
      return callback @_gatewayError() if error?
      return callback @_error(response.statusCode, body) if response.statusCode > 299
      callback null

  _gatewayError: =>
    @_error 502, 'Could not contact the shadow service'

  _error: (code, message) =>
    error = new Error message
    error.code = code ? 500
    return error

module.exports = ShadowService
