debug = require('debug')('gateblu-shadow-service:config-controller')
VirtualGateblu = require '../models/virtual-gateblu'

class ConfigController
  constructor: ({@shadowService}) ->

  update: (request, response) =>
    debug '422: no request.body.type' unless request.body.type?
    return response.sendStatus 422 unless request.body.type?
    debug '204: no request.body.shadowing.uuid' unless request.body.shadowing?.uuid?
    return response.sendStatus 204 unless request.body.shadowing?.uuid?
    debug 'proxy: not a gateblu' unless request.body.type == 'device:gateblu'
    return @proxy request, response unless request.body.type == 'device:gateblu'

    debug 'virtualGateblu: updateRealGateblu'
    virtualGateblu = new VirtualGateblu attributes: request.body, meshbluConfig: request.meshbluAuth
    virtualGateblu.updateRealGateblu (error) =>
      return @sendError {response, error} if error?
      debug "204: virtualGateblu update success"
      response.sendStatus 204

  proxy: ({body,meshbluAuth}, response) =>
    @shadowService.proxy {meshbluAuth, body}, (error) =>
      return @sendError {response, error} if error?
      debug "204: proxy success"
      response.sendStatus 204

  sendError: ({response,error}) =>
    debug "500: #{error.message}" unless error.code?
    return response.status(500).send error.message unless error.code?
    debug "#{error.code}: #{error.message}"
    return response.status(error.code).send error.message


module.exports = ConfigController
