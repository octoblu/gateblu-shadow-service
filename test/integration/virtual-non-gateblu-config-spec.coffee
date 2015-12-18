http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'

describe 'Non-Gateblu config event', ->
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
        teamAuth = new Buffer('team-uuid:team-token').toString 'base64'
        @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{teamAuth}"
          .reply 200, uuid: 'team-uuid', token: 'team-token'

        @proxyConfigToShadowService = @shadowService
          .post '/virtual/config'
          .set 'Authorization', "Basic #{teamAuth}"
          .send uuid: 'device-uuid', type: 'device:not-gateblu', foo: 'bar', shadowing: {uuid: 'some-uuid'}
          .reply 204

        options =
          baseUrl: "http://localhost:#{@serverPort}"
          uri: '/virtual/config'
          auth:
            username: 'team-uuid'
            password: 'team-token'
          json:
            uuid: 'device-uuid'
            type: 'device:not-gateblu'
            shadowing: {uuid: 'some-uuid'}
            foo: 'bar'

        request.post options, (error, @response, @body) => done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204, @body

      it 'should proxy the request to the shadow service', ->
        @proxyConfigToShadowService.done()

    describe 'When the shadow service responds with a 403', ->
      beforeEach (done) ->
        teamAuth = new Buffer('team-uuid:team-token').toString 'base64'
        @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{teamAuth}"
          .reply 200, uuid: 'team-uuid', token: 'team-token'

        @proxyConfigToShadowService = @shadowService
          .post '/virtual/config'
          .set 'Authorization', "Basic #{teamAuth}"
          .send uuid: 'device-uuid', type: 'device:not-gateblu', foo: 'bar', shadowing: {uuid: 'some-uuid'}
          .reply 403, 'Not authorized to modify that device'

        options =
          baseUrl: "http://localhost:#{@serverPort}"
          uri: '/virtual/config'
          auth:
            username: 'team-uuid'
            password: 'team-token'
          json:
            uuid: 'device-uuid'
            type: 'device:not-gateblu'
            foo: 'bar'
            shadowing: {uuid: 'some-uuid'}

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
          json:
            uuid: 'device-uuid'
            type: 'device:not-gateblu'
            foo: 'bar'
            shadowing: {uuid: 'some-uuid'}

        request.post options, (error, @response, @body) => done error

      it 'should return a 502', ->
        expect(@response.statusCode).to.equal 502, @body

      it 'should return a helpful error', ->
        expect(@body).to.deep.equal 'Could not contact the shadow service'
