_           = require 'lodash'
async       = require 'async'
request     = require 'request'
MeshbluHttp = require 'meshblu-http'

class VirtualGateblu
  constructor: ({@attributes,meshbluConfig}) ->
    @meshblu = new MeshbluHttp meshbluConfig

  devirtualizedDevice: ({uuid, connector, type}, callback) =>
    return callback @_userError 'malformed subdevice record', 422 unless uuid?
    @meshblu.device uuid, (error, virtualSubdevice) =>
      return callback error if error?
      realDeviceUuid = virtualSubdevice.shadowing.uuid
      return callback null, {uuid: realDeviceUuid, connector, type}

  devirtualizedDevices: (callback) =>
    async.mapSeries @attributes.devices, @devirtualizedDevice, callback

  updateRealGateblu: (callback) =>
    @devirtualizedDevices (error, subdeviceUuids) =>
      return callback error if error?

      realGatebluUuid = @attributes.shadowing.uuid
      @meshblu.update realGatebluUuid, devices: subdeviceUuids, callback

  _userError: (message, code) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = VirtualGateblu
