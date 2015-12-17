_           = require 'lodash'
async       = require 'async'
request     = require 'request'
MeshbluHttp = require 'meshblu-http'

class VirtualGateblu
  constructor: ({@attributes,meshbluConfig}) ->
    @meshblu = new MeshbluHttp meshbluConfig

  devirtualizedSubdeviceUuid: (uuid, callback) =>
    @meshblu.device uuid, (error, virtualSubdevice) =>
      return callback error if error?
      return callback null, virtualSubdevice.shadowing.uuid

  devirtualizedSubdeviceUuids: (callback) =>
    async.map @attributes.devices, @devirtualizedSubdeviceUuid, callback

  updateRealGateblu: (callback) =>
    @devirtualizedSubdeviceUuids (error, subdeviceUuids) =>
      return callback error if error?

      uuid = @attributes.shadowing.uuid
      update =
        $set:
          devices: subdeviceUuids

      @meshblu.updateDangerously uuid, update, callback

module.exports = VirtualGateblu
