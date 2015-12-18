http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'

describe 'Real invalid config events', ->
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

    describe 'When the request contains no body', ->
      beforeEach (done) ->
        gatebluAuth = new Buffer('real-gateblu-uuid:real-gateblu-token').toString 'base64'
        @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{gatebluAuth}"
          .reply 200, uuid: 'real-gateblu-uuid', token: 'real-gateblu-token'

        options =
          baseUrl: "http://localhost:#{@serverPort}"
          uri: '/real/config'
          auth:
            username: 'real-gateblu-uuid'
            password: 'real-gateblu-token'

        request.post options, (error, @response, @body) => done error

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422, @body

      it 'should have a descriptive error', ->
        expect(@body).to.deep.equal 'Unprocessable Entity'
