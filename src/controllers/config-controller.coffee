request = require 'request'

class ConfigController
  constructor: ({@shadowServiceUri}) ->

  update: (req, res) =>
    options =
      baseUrl: @shadowServiceUri
      uri: '/config'
      auth:
        user: req.meshbluAuth.uuid
        pass: req.meshbluAuth.token
      json:
        uuid: 'device-uuid'
        type: 'device:not-gateblu'
        foo: 'bar'

    request.post options, (error, response) ->
      return res.status(502).send 'Could not contact the shadow service' if error?
      res.status(response.statusCode).send response.body

module.exports = ConfigController
