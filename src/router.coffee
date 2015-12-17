ConfigController = require './controllers/config-controller'

class Router
  constructor: ({shadowService}) ->
    @configController = new ConfigController({shadowService})

  route: (app) =>
    app.post '/config', @configController.update

module.exports = Router
