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
        return callback() if @_theSame @attributes, virtualGateblu, subdeviceUuids
        update = {devices: subdeviceUuids, type: @attributes.type, name: @attributes.name}
        @meshblu.update uuid, update, callback

  virtualSubdeviceUuids: ({owner}, callback) =>
    virtualSubdevices = _.map @attributes.devices, (realUuid) =>
      new VirtualSubdevice {owner, realUuid, @meshbluConfig}

    async.map virtualSubdevices, @_getUuidForVirtualSubdevice, (error, subdeviceUuids) =>
      return callback error if error?
      return callback null, _.compact(subdeviceUuids)

  _getUuidForVirtualSubdevice: (virtualSubdevice, callback) =>
    virtualSubdevice.getUuid callback

  _theSame: (realGateblu,virtualGateblu,newSubdeviceUuids)=>
    return false unless virtualGateblu.name == realGateblu.name
    return false unless virtualGateblu.type == realGateblu.type
    changes = _.xor virtualGateblu.devices, newSubdeviceUuids
    return _.isEmpty(changes)

module.exports = RealGateblu
