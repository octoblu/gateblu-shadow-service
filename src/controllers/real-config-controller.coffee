_           = require 'lodash'
debug       = require('debug')('gateblu-shadow-service:real-config-controller')
GatebluShadower = require 'gateblu-shadower'

class RealConfigController
  constructor: ({@shadowService}) ->

  update: (request, response) =>
    return response.sendStatus 204 if _.isEmpty request.body.shadows
    return @proxy request, response unless request.body.type == 'device:gateblu'

    gatebluShadower = new GatebluShadower meshbluConfig: request.meshbluAuth
    gatebluShadower.updateVirtualsFromReal request.body, (error) =>
      return @sendError {response, error} if error?
      response.sendStatus 204

  proxy: ({body,meshbluAuth}, response) =>
    @shadowService.proxyReal {meshbluAuth, body}, (error) =>
      return @sendError {response, error} if error?
      response.sendStatus 204

  sendError: ({response,error}) =>
    return response.status(500).send error.message unless error.code?
    return response.status(error.code).send error.message

module.exports = RealConfigController
