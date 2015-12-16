http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'

describe 'Non-Gateblu config event', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    @shadowService = shmock 0xcafe

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
    @shadowService.close done

  afterEach (done) ->
    @meshblu.close done

  describe 'When called with valid auth', ->
    beforeEach (done) ->
      teamAuth = new Buffer('team-uuid:team-token').toString 'base64'
      @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{teamAuth}"
        .reply 200, uuid: 'team-uuid', token: 'team-token'

      @proxyConfigToShadowService = @shadowService
        .post '/config'
        .set 'Authorization', "Basic #{teamAuth}"
        .send uuid: 'device-uuid', type: 'device:not-gateblu', foo: 'bar'
        .reply 204

      options =
        baseUrl: "http://localhost:#{@serverPort}"
        uri: '/config'
        auth:
          username: 'team-uuid'
          password: 'team-token'
        json:
          uuid: 'device-uuid'
          type: 'device:not-gateblu'
          foo: 'bar'

      request.post options, (error, @response, @body) => done error

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204, @body

    it 'should proxy the request to the shadow service', ->
      @proxyConfigToShadowService.done()
