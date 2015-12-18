http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'

describe 'Real Gateblu config event', ->
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

  describe 'when the real gateblu and the real subdevice have only one shadow each', ->
    beforeEach (done) ->
      gatebluAuth = new Buffer('real-gateblu-uuid:real-gateblu-token').toString 'base64'

      @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{gatebluAuth}"
        .reply 200, uuid: 'real-gateblu-uuid', token: 'real-gateblu-token'

      @meshblu
        .get '/v2/devices/real-subdevice-uuid'
        .set 'Authorization', "Basic #{gatebluAuth}"
        .reply 200, shadows: [{uuid: 'virtual-subdevice-uuid', owner: 'user-uuid'}]

      @updateVirtualGatebluDevice = @meshblu
        .patch '/v2/devices/virtual-gateblu-uuid'
        .set 'Authorization', "Basic #{gatebluAuth}"
        .send devices: ['virtual-subdevice-uuid']
        .reply 204

      options =
        baseUrl: "http://localhost:#{@serverPort}"
        uri: '/real/config'
        auth:
          username: 'real-gateblu-uuid'
          password: 'real-gateblu-token'
        json:
          uuid: 'real-gateblu-uuid'
          type: 'device:gateblu'
          shadows: [{uuid: 'virtual-gateblu-uuid', owner: 'user-uuid'}]
          devices: ['real-subdevice-uuid']

      request.post options, (error, @response, @body) => done error

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204, @body

    it 'should update the real Gateblu device in Meshblu', ->
      @updateVirtualGatebluDevice.done()

  describe 'when the real gateblu and the real subdevice have two shadow each', ->
    beforeEach (done) ->
      gatebluAuth = new Buffer('real-gateblu-uuid:real-gateblu-token').toString 'base64'

      @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{gatebluAuth}"
        .reply 200, uuid: 'real-gateblu-uuid', token: 'real-gateblu-token'

      @meshblu
        .get '/v2/devices/real-subdevice-uuid'
        .set 'Authorization', "Basic #{gatebluAuth}"
        .persist()
        .reply 200, shadows: [
          {uuid: 'virtual-1-subdevice-uuid', owner:'user-1-uuid'}
          {uuid: 'virtual-2-subdevice-uuid', owner:'user-2-uuid'}
        ]

      @updateVirtualGatebluDevice1 = @meshblu
        .patch '/v2/devices/virtual-1-gateblu-uuid'
        .set 'Authorization', "Basic #{gatebluAuth}"
        .send devices: ['virtual-1-subdevice-uuid']
        .reply 204

      @updateVirtualGatebluDevice2 = @meshblu
        .patch '/v2/devices/virtual-2-gateblu-uuid'
        .set 'Authorization', "Basic #{gatebluAuth}"
        .send devices: ['virtual-2-subdevice-uuid']
        .reply 204

      options =
        baseUrl: "http://localhost:#{@serverPort}"
        uri: '/real/config'
        auth:
          username: 'real-gateblu-uuid'
          password: 'real-gateblu-token'
        json:
          uuid: 'real-gateblu-uuid'
          type: 'device:gateblu'
          shadows: [
            {uuid: 'virtual-1-gateblu-uuid', owner: 'user-1-uuid'}
            {uuid: 'virtual-2-gateblu-uuid', owner: 'user-2-uuid'}
          ]
          devices: ['real-subdevice-uuid']

      request.post options, (error, @response, @body) => done error

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204, @body

    it 'should update the first virtual Gateblu device in Meshblu', ->
      @updateVirtualGatebluDevice1.done()

    it 'should update the second virtual Gateblu device in Meshblu', ->
      @updateVirtualGatebluDevice1.done()

  xdescribe 'When the team does not have permission to update the real gateblu', ->
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

  xdescribe 'When the team does not have permission to see the virtual subdevice', ->
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

  xdescribe 'When the gateblu is not shadowing anything', ->
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
