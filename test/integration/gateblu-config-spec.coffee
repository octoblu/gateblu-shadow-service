http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'

describe 'Gateblu config event', ->
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

  describe 'When the config event is about a virtual gateblu', ->
    beforeEach (done) ->
      teamAuth = new Buffer('team-uuid:team-token').toString 'base64'

      @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{teamAuth}"
        .reply 200, uuid: 'team-uuid', token: 'team-token'

      @meshblu
        .get '/v2/devices/virtual-subdevice-uuid'
        .set 'Authorization', "Basic #{teamAuth}"
        .reply 200, shadowing: {uuid: 'real-subdevice-uuid'}

      @updateRealGatebluDevice = @meshblu
        .put '/v2/devices/real-gateblu-uuid'
        .set 'Authorization', "Basic #{teamAuth}"
        .send $set: {devices: ['real-subdevice-uuid']}
        .reply 204

      options =
        baseUrl: "http://localhost:#{@serverPort}"
        uri: '/virtual/config'
        auth:
          username: 'team-uuid'
          password: 'team-token'
        json:
          uuid: 'virtual-gateblu-uuid'
          type: 'device:gateblu'
          shadowing: {uuid: 'real-gateblu-uuid'}
          devices: ['virtual-subdevice-uuid']

      request.post options, (error, @response, @body) => done error

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204, @body

    it 'should update the real Gateblu device in Meshblu', ->
      @updateRealGatebluDevice.done()

  describe 'When the team does not have permission to update the real gateblu', ->
    beforeEach (done) ->
      teamAuth = new Buffer('team-uuid:team-token').toString 'base64'

      @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{teamAuth}"
        .reply 200, uuid: 'team-uuid', token: 'team-token'

      @meshblu
        .get '/v2/devices/virtual-subdevice-uuid'
        .set 'Authorization', "Basic #{teamAuth}"
        .reply 200, shadowing: {uuid: 'real-subdevice-uuid'}

      @meshblu
        .put '/v2/devices/real-gateblu-uuid'
        .set 'Authorization', "Basic #{teamAuth}"
        .send $set: {devices: ['real-subdevice-uuid']}
        .reply 403, error: 'No permission'

      options =
        baseUrl: "http://localhost:#{@serverPort}"
        uri: '/virtual/config'
        auth:
          username: 'team-uuid'
          password: 'team-token'
        json:
          uuid: 'virtual-gateblu-uuid'
          type: 'device:gateblu'
          shadowing: {uuid: 'real-gateblu-uuid'}
          devices: ['virtual-subdevice-uuid']

      request.post options, (error, @response, @body) => done error

    it 'should return a 403', ->
      expect(@response.statusCode).to.equal 403, @body

    it 'should return a usefull error message', ->
      expect(@body).to.deep.equal 'No permission'

  describe 'When the team does not have permission to see the virtual subdevice', ->
    beforeEach (done) ->
      teamAuth = new Buffer('team-uuid:team-token').toString 'base64'

      @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{teamAuth}"
        .reply 200, uuid: 'team-uuid', token: 'team-token'

      @meshblu
        .get '/v2/devices/virtual-subdevice-uuid'
        .set 'Authorization', "Basic #{teamAuth}"
        .reply 403, 'You do not belong here'

      options =
        baseUrl: "http://localhost:#{@serverPort}"
        uri: '/virtual/config'
        auth:
          username: 'team-uuid'
          password: 'team-token'
        json:
          uuid: 'virtual-gateblu-uuid'
          type: 'device:gateblu'
          shadowing: {uuid: 'real-gateblu-uuid'}
          devices: ['virtual-subdevice-uuid']

      request.post options, (error, @response, @body) => done error

    it 'should return a 403', ->
      expect(@response.statusCode).to.equal 403, @body

    it 'should return a usefull error message', ->
      expect(@body).to.deep.equal 'You do not belong here'

  describe 'When the gateblu is not shadowing anything', ->
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
          uuid: 'virtual-gateblu-uuid'
          type: 'device:gateblu'
          devices: ['virtual-subdevice-uuid']

      request.post options, (error, @response, @body) => done error

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204, @body
