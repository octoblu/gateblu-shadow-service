request = require 'request'

class ShadowService
  constructor: ({@shadowServiceUri}) ->


  proxyReal: ({meshbluAuth,body}, callback) =>
    path = '/real/config'
    @_proxy {meshbluAuth, body, path}, callback

  proxyVirtual: ({meshbluAuth,body}, callback) =>
    path = '/virtual/config'
    @_proxy {meshbluAuth, body, path}, callback

  _gatewayError: =>
    @_error 502, 'Could not contact the shadow service'

  _error: (code, message) =>
    error = new Error message
    error.code = code ? 500
    return error

  _proxy: ({meshbluAuth,body,path}, callback) =>
    options =
      baseUrl: @shadowServiceUri
      uri: path
      auth:
        username: meshbluAuth.uuid
        password: meshbluAuth.token
      json: body

    request.post options, (error, response, body) =>
      return callback @_gatewayError() if error?
      return callback @_error(response.statusCode, body) if response.statusCode > 299
      callback null

module.exports = ShadowService
