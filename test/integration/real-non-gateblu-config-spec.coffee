http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'

describe 'Real Non-Gateblu config event', ->
  describe 'with a shadow service', ->
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

    describe 'When the shadow service responds with a 204', ->
      beforeEach (done) ->
        deviceAuth = new Buffer('real-device-uuid:real-device-token').toString 'base64'
        @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'real-device-uuid', token: 'real-device-token'

        @proxyConfigToShadowService = @shadowService
          .post '/real/config'
          .set 'Authorization', "Basic #{deviceAuth}"
          .send uuid: 'real-device-uuid', type: 'device:not-gateblu', foo: 'bar', shadows: [{uuid: 'some-uuid'}]
          .reply 204

        options =
          baseUrl: "http://localhost:#{@serverPort}"
          uri: '/real/config'
          auth:
            username: 'real-device-uuid'
            password: 'real-device-token'
          json:
            uuid: 'real-device-uuid'
            type: 'device:not-gateblu'
            shadows: [{uuid: 'some-uuid'}]
            foo: 'bar'

        request.post options, (error, @response, @body) => done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204, @body

      it 'should proxy the request to the shadow service', ->
        @proxyConfigToShadowService.done()

    describe 'When the shadow service responds with a 403', ->
      beforeEach (done) ->
        deviceAuth = new Buffer('real-device-uuid:real-device-token').toString 'base64'
        @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'real-device-uuid', token: 'real-device-token'

        @proxyConfigToShadowService = @shadowService
          .post '/real/config'
          .set 'Authorization', "Basic #{deviceAuth}"
          .send uuid: 'device-uuid', type: 'device:not-gateblu', foo: 'bar', shadows: [{uuid: 'some-uuid'}]
          .reply 403, 'Not authorized to modify that device'

        options =
          baseUrl: "http://localhost:#{@serverPort}"
          uri: '/real/config'
          auth:
            username: 'real-device-uuid'
            password: 'real-device-token'
          json:
            uuid: 'device-uuid'
            type: 'device:not-gateblu'
            foo: 'bar'
            shadows: [{uuid: 'some-uuid'}]

        request.post options, (error, @response, @body) => done error

      it 'should return a 403', ->
        expect(@response.statusCode).to.equal 403, @body

      it 'should return the shadow service error', ->
        expect(@body).to.deep.equal 'Not authorized to modify that device'

      it 'should proxy the request to the shadow service', ->
        @proxyConfigToShadowService.done()

  describe 'with no shadow service', ->
    beforeEach (done) ->
      @meshblu = shmock 0xd00d

      @server = new Server
        port: undefined,
        disableLogging: true
        shadowServiceUri: "https://localhost:#{0xcafe}"
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

    describe 'When a request is made', ->
      beforeEach (done) ->
        deviceAuth = new Buffer('real-device-uuid:real-device-token').toString 'base64'
        @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'real-device-uuid', token: 'real-device-token'

        options =
          baseUrl: "http://localhost:#{@serverPort}"
          uri: '/real/config'
          auth:
            username: 'real-device-uuid'
            password: 'real-device-token'
          json:
            uuid: 'device-uuid'
            type: 'device:not-gateblu'
            foo: 'bar'
            shadows: [{uuid: 'some-uuid'}]

        request.post options, (error, @response, @body) => done error

      it 'should return a 502', ->
        expect(@response.statusCode).to.equal 502, @body

      it 'should return a helpful error', ->
        expect(@body).to.deep.equal 'Could not contact the shadow service'
