RealConfigController    = require './controllers/real-config-controller'
VirtualConfigController = require './controllers/virtual-config-controller'

class Router
  constructor: ({shadowService}) ->
    @realConfigController = new RealConfigController({shadowService})
    @virtualConfigController = new VirtualConfigController({shadowService})

  route: (app) =>
    app.post '/real/config', @realConfigController.update
    app.post '/virtual/config', @virtualConfigController.update

module.exports = Router
