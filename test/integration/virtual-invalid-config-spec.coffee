http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'

describe 'Virtual invalid config events', ->
  describe 'with a shadow service', ->
    beforeEach (done) ->
      @meshblu = shmock 0xd00d

      @server = new Server
        port: undefined,
        disableLogging: true
        shadowServiceUri: "http://localhost:#{0xcafe}"
        meshbluConfig:
          server: 'localhost'
          port: 0xd00d

      @server.run =>
        @serverPort = @server.address().port
        done()

    afterEach (done) ->
      @server.stop done

    afterEach (done) ->
      @meshblu.close done
