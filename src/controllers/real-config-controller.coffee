debug       = require('debug')('gateblu-shadow-service:real-config-controller')
RealGateblu = require '../models/real-gateblu'

class RealConfigController
  constructor: ({@shadowService}) ->

  update: (request, response) =>
    debug 'proxy: not a gateblu' unless request.body.type == 'device:gateblu'
    return @proxy request, response unless request.body.type == 'device:gateblu'

    debug 'realGateblu: updateVirtualGateblus'
    realGateblu = new RealGateblu attributes: request.body, meshbluConfig: request.meshbluAuth
    realGateblu.updateVirtualGateblus (error) =>
      return @sendError {response, error} if error?
      response.sendStatus 204

  proxy: ({body,meshbluAuth}, response) =>
    @shadowService.proxyReal {meshbluAuth, body}, (error) =>
      return @sendError {response, error} if error?
      debug "204: proxy success"
      response.sendStatus 204

  sendError: ({response,error}) =>
    debug "500: #{error.message}" unless error.code?
    return response.status(500).send error.message unless error.code?
    debug "#{error.code}: #{error.message}"
    return response.status(error.code).send error.message

module.exports = RealConfigController