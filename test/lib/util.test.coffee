#
# Copyright (c) 2015, Kinvey, Inc. All rights reserved.
#
# This software is licensed to you under the Kinvey terms of service located at
# http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
# software, you hereby accept such terms of service  (and any agreement referenced
# therein) and agree that you have read, understand and agree to be bound by such
# terms of service and are of legal age to agree to such terms with Kinvey.
#
# This software contains valuable confidential and proprietary information of
# KINVEY, INC and is subject to applicable licensing agreements.
# Unauthorized reproduction, transmission or distribution of this file and its
# contents is a violation of applicable laws.
#

# Package modules.
proxyquire = require 'proxyquire'
should     = require 'should'
sinon      = require 'sinon'

# Configure mocks.
class ContainerMock
  start: sinon.stub()

class DockerMock
  modem: { followProgress: sinon.stub() }
  createContainer : sinon.stub()
  listContainers  : sinon.stub()
  ping : sinon.stub()
  pull : sinon.stub()

# Test suite.
describe 'Business Logic Tester / utility tests', ->

  # Load unit under test.
  testModule = proxyquire '../../lib/util', { dockerode: DockerMock }

  # Reset mocks.
  beforeEach 'stubs', ->
    DockerMock.prototype.modem.followProgress.callsArgWithAsync 1, null, 'data'
    DockerMock.prototype.createContainer.callsArgWithAsync 1, null, new ContainerMock()
    DockerMock.prototype.listContainers.callsArgWithAsync  0, null, [ ]
    DockerMock.prototype.ping.callsArgAsync 0
    DockerMock.prototype.pull.callsArgWithAsync 1, null, 'stream'
    ContainerMock.prototype.start.callsArgAsync 1
  afterEach 'stubs', ->
    DockerMock.prototype.modem.followProgress.reset()
    DockerMock.prototype.createContainer.reset()
    DockerMock.prototype.listContainers.reset()
    DockerMock.prototype.ping.reset()
    DockerMock.prototype.pull.reset()
    ContainerMock.prototype.start.reset()

  # Setup method.
  describe 'setup', ->
    # Set set-up options.
    beforeEach 'options', -> @options = { blRootPath: __dirname, environmentID: 'test' }
    afterEach  'options', -> delete @options # Cleanup.

    # Tests.
    it 'should fail if Docker is not running.', (done) ->
      DockerMock.prototype.ping.callsArgWithAsync 0, new Error 'STOP'

      testModule.setup @options, (err) ->
        err.should.exist
        err.toString().should.containEql 'Docker'
        done()

    it 'should re-use an already-running Docker container.', (done) ->
      DockerMock.prototype.listContainers.callsArgWith 0, null, [ {
        Image: 'kinvey/blrunner:latest'
      }]

      testModule.setup @options, (err) ->
        # Module should *not* pull the image and create a new container.
        DockerMock.prototype.pull.called.should.be.false
        DockerMock.prototype.createContainer.called.should.be.false
        done err

    it 'should pull the Docker image and start a Docker container.', (done) ->
      DockerMock.prototype.listContainers.callsArgWith 0, null, [ { Image: 'foo' }]

      testModule.setup @options, (err) ->
        DockerMock.prototype.pull.called.should.be.true
        DockerMock.prototype.createContainer.called.should.be.true
        ContainerMock.prototype.start.called.should.be.true
        done err

    it 'should setup the client.', (done) ->
      testModule.setup @options, (err, client) =>
        client.should.exist
        client.configuration.environmentID.should.eql @options.environmentID
        client.configuration.blRootPath.should.eql    @options.blRootPath
        done err

  # Teardown method.
  describe 'teardown method', ->
    # Tests.
    it 'should run.', (done) ->
      testModule.teardown { }, done