_                = require 'lodash'
async            = require 'async'
MeshbluHttp      = require 'meshblu-http'
VirtualSubdevice = require './virtual-subdevice'

class RealGateblu
  constructor: ({@attributes,@meshbluConfig}) ->
    @meshblu = new MeshbluHttp @meshbluConfig

  updateVirtualGateblus: (callback) =>
    async.each @attributes.shadows, @updateVirtualGateblu, callback

  updateVirtualGateblu: ({uuid,owner}, callback) =>
    @virtualSubdeviceUuids {owner}, (error, subdeviceUuids) =>
      return callback error if error?
      @meshblu.device uuid, (error, virtualGateblu) =>
        return callback error if error?
        changes = _.xor virtualGateblu.devices, subdeviceUuids
        return callback() if _.isEmpty changes
        @meshblu.update uuid, {devices: subdeviceUuids}, callback

  virtualSubdeviceUuids: ({owner}, callback) =>
    virtualSubdevices = _.map @attributes.devices, (realUuid) =>
      new VirtualSubdevice {owner, realUuid, @meshbluConfig}

    async.map virtualSubdevices, @_getUuidForVirtualSubdevice, (error, subdeviceUuids) =>
      return callback error if error?
      return callback null, _.compact(subdeviceUuids)

  _getUuidForVirtualSubdevice: (virtualSubdevice, callback) =>
    virtualSubdevice.getUuid callback

module.exports = RealGateblu
