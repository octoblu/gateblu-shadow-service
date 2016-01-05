debug = require('debug')('gateblu-shadow-service:virtual-config-controller')
GatebluShadower = require 'gateblu-shadower'

class VirtualConfigController
  constructor: ({@shadowService}) ->

  update: (request, response) =>
    debug '204: no request.body.shadowing.uuid' unless request.body.shadowing?.uuid?
    return response.sendStatus 204 unless request.body.shadowing?.uuid?
    debug 'proxy: not a gateblu' unless request.body.type == 'device:gateblu'
    return @proxy request, response unless request.body.type == 'device:gateblu'

    debug 'virtualGateblu: updateRealGateblu'
    gatebluShadower = new GatebluShadower meshbluConfig: request.meshbluAuth
    gatebluShadower.updateRealFromVirtual request.body, (error) =>
      return @sendError {response, error} if error?
      debug "204: virtualGateblu update success"
      response.sendStatus 204

  proxy: ({body,meshbluAuth}, response) =>
    @shadowService.proxyVirtual {meshbluAuth, body}, (error) =>
      return @sendError {response, error} if error?
      debug "204: proxy success"
      response.sendStatus 204

  sendError: ({response,error}) =>
    debug "500: #{error.message}" unless error.code?
    return response.status(500).send error.message unless error.code?
    debug "#{error.code}: #{error.message}"
    return response.status(error.code).send error.message


module.exports = VirtualConfigController
