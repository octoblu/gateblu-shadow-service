http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'

describe 'Invalid config events', ->
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
        teamAuth = new Buffer('team-uuid:team-token').toString 'base64'
        @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{teamAuth}"
          .reply 200, uuid: 'team-uuid', token: 'team-token'

        options =
          baseUrl: "http://localhost:#{@serverPort}"
          uri: '/virtual/config'
          auth:
            username: 'team-uuid'
            password: 'team-token'

        request.post options, (error, @response, @body) => done error

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422, @body

      it 'should have a descriptive error', ->
        expect(@body).to.deep.equal 'Unprocessable Entity'
