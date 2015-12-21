_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class VirtualSubdevice
  constructor: ({@owner, @realUuid, meshbluConfig}) ->
    @meshblu = new MeshbluHttp meshbluConfig

  getUuid: (callback) =>
    @meshblu.device @realUuid, (error, device) =>
      return callback error if error?

      virtualDevice = _.findWhere device.shadows, {@owner}
      callback null, virtualDevice?.uuid


module.exports = VirtualSubdevice
