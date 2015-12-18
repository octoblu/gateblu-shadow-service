debug = require('debug')('gateblu-shadow-service:config-controller')
VirtualGateblu = require '../models/virtual-gateblu'

class ConfigController
  constructor: ({@shadowService}) ->

  update: (request, response) =>
    return response.sendStatus 422 unless request.body.type?
    return response.sendStatus 204 unless request.body.shadowing?.uuid?
    return @proxy request, response unless request.body.type == 'device:gateblu'

    virtualGateblu = new VirtualGateblu attributes: request.body, meshbluConfig: request.meshbluAuth
    virtualGateblu.updateRealGateblu (error) =>
      debug 'updateRealGateblu', error
      return @sendError {response, error} if error?
      response.sendStatus 204

  proxy: ({body,meshbluAuth}, response) =>
    @shadowService.proxy {meshbluAuth, body}, (error) =>
      return @sendError {response, error} if error?
      response.sendStatus 204

  sendError: ({response,error}) =>
    return response.status(500).send error.message unless error.code?
    return response.status(error.code).send error.message


module.exports = ConfigController
