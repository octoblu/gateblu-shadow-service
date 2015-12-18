_           = require 'lodash'
async       = require 'async'
MeshbluHttp = require 'meshblu-http'

class RealGateblu
  constructor: ({@attributes,@meshbluConfig}) ->
    @meshblu = new MeshbluHttp @meshbluConfig

  updateVirtualGateblus: (callback) =>
    async.each @attributes.shadows, @updateVirtualGateblu, callback

  updateVirtualGateblu: ({uuid,owner}, callback) =>
    @virtualSubdeviceUuids {owner}, (error, subdeviceUuids) =>
      return callback error if error?
      @meshblu.update uuid, {devices: subdeviceUuids}, callback

  virtualSubdeviceUuids: ({owner}, callback) =>
    getVirtualSubdeviceUuid = (subdeviceUuid, callback) =>
      @virtualSubdeviceUuid {owner, subdeviceUuid}, callback

    async.map @attributes.devices, getVirtualSubdeviceUuid, (error, subdeviceUuids) =>
      return callback error if error?
      return callback null, _.compact(subdeviceUuids)

  virtualSubdeviceUuid: ({owner, subdeviceUuid}, callback) =>
    @meshblu.device subdeviceUuid, (error, subdevice) =>
      return callback error if error?

      subdevice = _.findWhere subdevice.shadows, {owner}
      callback null, subdevice?.uuid

module.exports = RealGateblu
