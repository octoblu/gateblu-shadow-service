_ = require 'lodash'

class ConfigController
  constructor: ({@shadowService}) ->

  update: (req, res) =>
    meshbluAuth = _.pick req.meshbluAuth, 'uuid', 'token'
    body = req.body

    @shadowService.proxy {meshbluAuth, body}, (error, response) =>
      return res.status(500).send error.message if error?
      res.status(response.statusCode).send response.body

module.exports = ConfigController
