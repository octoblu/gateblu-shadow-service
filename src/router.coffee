ConfigController = require './controllers/config-controller'

class Router
  constructor: ({shadowServiceUri}) ->
    @configController = new ConfigController({shadowServiceUri})

  route: (app) =>
    app.post '/config', @configController.update

module.exports = Router
