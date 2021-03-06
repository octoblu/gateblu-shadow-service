cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
meshbluAuth        = require 'express-meshblu-auth'
debug              = require('debug')('gateblu-shadow-service:server')
Router             = require './router'
ShadowService      = require './services/shadow-service'

class Server
  constructor: (options)->
    {@disableLogging, @port} = options
    {@meshbluConfig, shadowServiceUri} = options
    @shadowService =  new ShadowService {shadowServiceUri}

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use meshbluAuth(@meshbluConfig)
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'

    app.options '*', cors()

    router = new Router
      meshbluConfig: @meshbluConfig
      shadowService: @shadowService
    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
