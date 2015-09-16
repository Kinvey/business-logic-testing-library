#
# Copyright 2015 Kinvey, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

fs = require 'fs'
path = require 'path'
should = require 'should'
sinon = require 'sinon'
proxyquire = require 'proxyquire'
rimraf = require 'rimraf'
config = require 'config'

testFunctionString = 'function onRequest(request, response, modules){\n  response.body = { testPassed: true };\n  response.complete();\n}'

tempBlDirectoryName = 'test/tempTest'

describe 'Business Logic Tester / unit tests', () ->
  socketEventListeners = {}
  socketMock =
    on: (eventName, callback) ->
      socketEventListeners[eventName] = callback
    write: sinon.spy()
    end: sinon.spy()

  netMock = {}

  childProcessMock =
    exec: sinon.mock()

  childProcessMock.exec.callsArg 1

  testModule = proxyquire '../../lib/tester', { net: netMock, child_process: childProcessMock }

  dockerHost = process.env.DOCKER_HOST

  executeTesterMethodThroughMock = (tester, methodName, methodArguments...) ->
    socketMock.write.reset()

    originalCallback = methodArguments[methodArguments.length - 1]
    methodArguments[methodArguments.length - 1] = () ->
      originalCallback JSON.parse socketMock.write.args[0]

    tester[methodName].apply tester, methodArguments

    setTimeout () ->
      should.exist socketEventListeners['data']
      socketEventListeners['data'](JSON.stringify({}) + '\n')
    , 5

  before (done) ->
    delete process.env.DOCKER_HOST

    # create BL file structure
    fs.mkdirSync tempBlDirectoryName

    for directoryType, directoryName of config.directories
      fs.mkdirSync tempBlDirectoryName + '/' + directoryName

    done()

  after (done) ->
    process.env.DOCKER_HOST = dockerHost

    # remove the temporary BL directory and all its contents
    rimraf tempBlDirectoryName, done

  afterEach (done) ->
    childProcessMock.exec.reset()
    done()

  describe 'configuration', () ->
    it 'creates a connection to the specified docker host and port', (done) ->
      netMock.createConnection = sinon.mock()
      netMock.createConnection.returns socketMock

      options =
        quiet: true
        runnerPort: 'docker.port.test'
        containerHostOrIP: '10.10.10.10'

      testModule.createClient options, (err, tester) ->
        if err then return done err
        tester.runFunction testFunctionString, {}, {}
        netMock.createConnection.calledWith(options.runnerPort, options.containerHostOrIP).should.be.true
        done()

    it 'uses defaults from config file if host and port are not specified', (done) ->
      netMock.createConnection = sinon.mock()
      netMock.createConnection.returns socketMock

      options =
        quiet: true

      testModule.createClient options, (err, tester) ->
        if err then return done err
        tester.runFunction testFunctionString, {}, {}
        netMock.createConnection.calledWith(config.runnerPort, config.containerHostOrIP).should.be.true
        done()


    it 'uses DOCKER_HOST if defined', (done) ->
      netMock.createConnection = sinon.mock()
      netMock.createConnection.returns socketMock

      process.env.DOCKER_HOST = 'tcp://test-docker-host:port'

      options =
        quiet: true

      testModule.createClient options, (err, tester) ->
        if err then return done err
        tester.runFunction testFunctionString, {}, {}
        netMock.createConnection.calledWith(config.runnerPort, 'test-docker-host').should.be.true
        delete process.env.DOCKER_HOST
        done()

    it "uses output from 'docker ps', if available, to find port mappings", (done) ->
      netMock.createConnection = sinon.mock()
      netMock.createConnection.returns socketMock

      options =
        quiet: true

      childProcessMock.exec.callsArgWith 1, null, "888888->#{config.proxyPort}, 222222->#{config.runnerPort}"

      testModule.createClient options, (err, tester) ->
        if err then return done err
        tester.runFunction testFunctionString, {}, {}
        netMock.createConnection.calledWith('222222', config.containerHostOrIP).should.be.true
        done()

    it 'accepts environmentID config option', (done) ->
      netMock.createConnection = (port, host, callback) ->
        setTimeout callback, 5
        return socketMock

      options =
        quiet: true
        environmentID: 'testing-environment-id'

      testModule.createClient options, (err, tester) ->
        if err then return done err
        executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
          parsedJSONTask.should.have.property 'appId'
          parsedJSONTask.appId.should.eql options.environmentID
          done()

    it 'uses default environmentID from config file if not specified', (done) ->
      netMock.createConnection = (port, host, callback) ->
        setTimeout callback, 5
        return socketMock

      options =
        quiet: true

      testModule.createClient options, (err, tester) ->
        if err then return done err
        executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
          parsedJSONTask.should.have.property 'appId'
          parsedJSONTask.appId.should.eql config.environmentID
          done()

    it 'accepts appSecret config option', (done) ->
      netMock.createConnection = (port, host, callback) ->
        setTimeout callback, 5
        return socketMock

      options =
        quiet: true
        appSecret: 'testing-environment-app-secret'

      testModule.createClient options, (err, tester) ->
        if err then return done err
        executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
          parsedJSONTask.appMetadata.should.have.property 'appsecret'
          parsedJSONTask.appMetadata.appsecret.should.eql options.appSecret
          done()

    it 'generates an appSecret based on the environment ID if one is not specified', (done) ->
      netMock.createConnection = (port, host, callback) ->
        setTimeout callback, 5
        return socketMock

      options =
        quiet: true

      testModule.createClient options, (err, tester) ->
        if err then return done err
        executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
          parsedJSONTask.appMetadata.should.have.property 'appsecret'
          parsedJSONTask.appMetadata.appsecret.should.eql "#{config.environmentID}-app-secret"
          done()

    it 'accepts masterSecret config option', (done) ->
      netMock.createConnection = (port, host, callback) ->
        setTimeout callback, 5
        return socketMock

      options =
        quiet: true
        masterSecret: 'testing-environment-app-secret'

      testModule.createClient options, (err, tester) ->
        if err then return done err
        executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
          parsedJSONTask.appMetadata.should.have.property 'mastersecret'
          parsedJSONTask.appMetadata.mastersecret.should.eql options.masterSecret
          done()

    it 'generates an masterSecret based on the environment ID if one is not specified', (done) ->
      netMock.createConnection = (port, host, callback) ->
        setTimeout callback, 5
        return socketMock

      options =
        quiet: true

      testModule.createClient options, (err, tester) ->
        if err then return done err
        executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
          parsedJSONTask.appMetadata.should.have.property 'mastersecret'
          parsedJSONTask.appMetadata.mastersecret.should.eql "#{config.environmentID}-master-secret"
          done()

  describe 'runCollectionHook method', () ->
    collectionHookName = 'testCollectionHook'
    tester = null

    before (done) ->
      options =
        quiet: true
        blRootPath: tempBlDirectoryName

      testModule.createClient options, (err, testerInstance) ->
        if err then return done err
        tester = testerInstance
        collectionDir = path.join options.blRootPath, config.directories.pathToCollections, collectionHookName
        fs.mkdirSync collectionDir

        fileName = path.join collectionDir, 'onPreSave.js'
        fs.writeFileSync fileName, testFunctionString

        netMock.createConnection = (port, host, callback) ->
          setTimeout callback, 5
          return socketMock
        done()

    afterEach (done) ->
      socketEventListeners = {}
      socketMock.end.reset()
      done()

    it 'fails if collection folder does not exist', (done) ->
      tester.runCollectionHook 'fakeCollectionName', 'onPostFetch', {}, {}, (err) ->
        should.exist err
        err.name.should.eql 'BLFileNotFoundError'
        done()

    it 'fails if file does not exist', (done) ->
      tester.runCollectionHook collectionHookName, 'onPostFetch', {}, {}, (err) ->
        should.exist err
        err.name.should.eql 'BLFileNotFoundError'
        done()

    it 'passes the function string to the container', (done) ->
      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'blScript'
        parsedJSONTask.blScript.should.eql testFunctionString
        done()

    it 'passes the request object to the container', (done) ->
      requestObject =
        body:
          test: 123
        headers:
          'x-kinvey-my-header': 'abc'

      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', requestObject, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'request'
        parsedJSONTask.request.body.should.eql requestObject.body
        parsedJSONTask.request.headers.should.eql requestObject.headers
        done()

    it 'passes the response object to the container', (done) ->
      responseObject =
        body:
          test: 123
        headers:
          'x-kinvey-my-header': 'abc'

      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', {}, responseObject, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'response'
        parsedJSONTask.response.body.should.eql responseObject.body
        parsedJSONTask.response.headers.should.eql responseObject.headers
        done()

    it 'sets the request method to POST for onPreSave and onPostSave', (done) ->
      fileName = path.join tempBlDirectoryName, config.directories.pathToCollections, collectionHookName, 'onPostSave.js'
      fs.writeFileSync fileName, testFunctionString

      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', {}, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'method'
        parsedJSONTask.request.method.should.eql 'POST'
        executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPostSave', {}, {}, (parsedJSONTask) ->
          parsedJSONTask.request.should.have.property 'method'
          parsedJSONTask.request.method.should.eql 'POST'
          done()

    it 'sets the request method to GET for onPreFetch and onPostFetch', (done) ->
      fileName = path.join tempBlDirectoryName, config.directories.pathToCollections, collectionHookName, 'onPreFetch.js'
      fs.writeFileSync fileName, testFunctionString

      fileName = path.join tempBlDirectoryName, config.directories.pathToCollections, collectionHookName, 'onPostFetch.js'
      fs.writeFileSync fileName, testFunctionString

      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreFetch', {}, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'method'
        parsedJSONTask.request.method.should.eql 'GET'
        executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPostFetch', {}, {}, (parsedJSONTask) ->
          parsedJSONTask.request.should.have.property 'method'
          parsedJSONTask.request.method.should.eql 'GET'
          done()

    it 'sets the request method to DELETE for onPreDelete and onPostDelete', (done) ->
      fileName = path.join tempBlDirectoryName, config.directories.pathToCollections, collectionHookName, 'onPreDelete.js'
      fs.writeFileSync fileName, testFunctionString

      fileName = path.join tempBlDirectoryName, config.directories.pathToCollections, collectionHookName, 'onPostDelete.js'
      fs.writeFileSync fileName, testFunctionString

      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreDelete', {}, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'method'
        parsedJSONTask.request.method.should.eql 'DELETE'
        executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPostDelete', {}, {}, (parsedJSONTask) ->
          parsedJSONTask.request.should.have.property 'method'
          parsedJSONTask.request.method.should.eql 'DELETE'
          done()

    it 'sets the request collection name to runCollectionHook', (done) ->
      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', {}, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'collectionName'
        parsedJSONTask.request.collectionName.should.eql collectionHookName
        done()

    it 'properly sets the targetFunction', (done) ->
      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'targetFunction'
        parsedJSONTask.targetFunction.should.eql 'onPreSave'
        done()

    it 'sets the hookType to collectionHook', (done) ->
      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'hookType'
        parsedJSONTask.hookType.should.eql 'collectionHook'
        done()

    it 'sets the request entityId to request.params.id or request.params.userid', (done) ->
      requestObject =
        params:
          id: 'testId'

      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', requestObject, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'entityId'
        parsedJSONTask.request.entityId.should.eql requestObject.params.id

        requestObject =
          params:
            userid: 'testUserId'

        executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', requestObject, {}, (parsedJSONTask) ->
          parsedJSONTask.request.should.have.property 'entityId'
          parsedJSONTask.request.entityId.should.eql requestObject.params.userid
          done()

    it 'loads common BL code if any is present in the specified folder', (done) ->
      commonFiles = ['var helped = false;\nvar helperFunction = function(){\n  helped = true;\n}',
                     'var helped2 = false;\nvar helperFunction2 = function(){\n  helped2 = true;\n}']

      for commonFileContents, i in commonFiles
        fileName = path.join tempBlDirectoryName, config.directories.pathToCommonFiles, "testCommonBlCode#{i}.js"
        fs.writeFileSync fileName, commonFileContents

      executeTesterMethodThroughMock tester, 'runCollectionHook', collectionHookName, 'onPreSave', {}, {}, (parsedJSONTask) ->
        parsedJSONTask.blScript.should.eql commonFiles.join('\n;') + '\n;' + testFunctionString

        # cleanup
        commonFileDir = path.join tempBlDirectoryName, config.directories.pathToCommonFiles
        rimraf commonFileDir, () ->
          fs.mkdir commonFileDir
          done()

  describe 'runCustomEndpoint method', () ->
    endpointName = 'testEndpointName'
    tester = null

    before (done) ->
      options =
        quiet: true
        blRootPath: tempBlDirectoryName

      testModule.createClient options, (err, testerInstance) ->
        if err then return done err

        tester = testerInstance

        fileName = path.join options.blRootPath, config.directories.pathToCustomEndpoints, "#{endpointName}.js"
        fs.writeFileSync fileName, testFunctionString

        netMock.createConnection = (port, host, callback) ->
          setTimeout callback, 5
          return socketMock
        done()

    afterEach (done) ->
      socketEventListeners = {}
      socketMock.end.reset()
      done()

    it 'fails if file does not exist', (done) ->
      tester.runCustomEndpoint 'fakeEndpointName', {}, {}, (err) ->
        should.exist err
        err.name.should.eql 'BLFileNotFoundError'
        done()

    it 'passes the function string to the container', (done) ->
      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'blScript'
        parsedJSONTask.blScript.should.eql testFunctionString
        done()

    it 'passes the request object to the container', (done) ->
      requestObject =
        body:
          test: 123
        headers:
          'x-kinvey-my-header': 'abc'

      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, requestObject, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'request'
        parsedJSONTask.request.body.should.eql requestObject.body
        parsedJSONTask.request.headers.should.eql requestObject.headers
        done()

    it 'passes the response object to the container', (done) ->
      responseObject =
        body:
          test: 123
        headers:
          'x-kinvey-my-header': 'abc'

      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, {}, responseObject, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'response'
        parsedJSONTask.response.body.should.eql responseObject.body
        parsedJSONTask.response.headers.should.eql responseObject.headers
        done()

    it 'sets the request method to POST', (done) ->
      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'method'
        parsedJSONTask.request.method.should.eql 'POST'
        done()

    it 'sets the request collection name to runCustomEndpoint', (done) ->
      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'collectionName'
        parsedJSONTask.request.collectionName.should.eql endpointName
        done()

    it 'sets the targetFunction to onRequest', (done) ->
      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'targetFunction'
        parsedJSONTask.targetFunction.should.eql 'onRequest'
        done()

    it 'sets the hookType to customEndpoint', (done) ->
      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'hookType'
        parsedJSONTask.hookType.should.eql 'customEndpoint'
        done()

    it 'loads common BL code if any is present in the specified folder', (done) ->
      commonFiles = ['var helped = false;\nvar helperFunction = function(){\n  helped = true;\n}',
                     'var helped2 = false;\nvar helperFunction2 = function(){\n  helped2 = true;\n}']

      for commonFileContents, i in commonFiles
        fileName = path.join tempBlDirectoryName, config.directories.pathToCommonFiles, "testCommonBlCode#{i}.js"
        fs.writeFileSync fileName, commonFileContents

      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.blScript.should.eql commonFiles.join('\n;') + '\n;' + testFunctionString

        # cleanup
        commonFileDir = path.join tempBlDirectoryName, config.directories.pathToCommonFiles
        rimraf commonFileDir, () ->
          fs.mkdir commonFileDir
          done()

    it 'sets the request entityId to request.params.id or request.params.userid', (done) ->
      requestObject =
        params:
          id: 'testId'

      executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, requestObject, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'entityId'
        parsedJSONTask.request.entityId.should.eql requestObject.params.id

        requestObject =
          params:
            userid: 'testUserId'

        executeTesterMethodThroughMock tester, 'runCustomEndpoint', endpointName, requestObject, {}, (parsedJSONTask) ->
          parsedJSONTask.request.should.have.property 'entityId'
          parsedJSONTask.request.entityId.should.eql requestObject.params.userid
          done()

  describe 'runFunction method', () ->
    tester = null

    before (done) ->
      testModule.createClient { quiet: true }, (err, testerInstance) ->
        if err then return done err

        tester = testerInstance

        netMock.createConnection = (port, host, callback) ->
          setTimeout callback, 5
          return socketMock
        done()

    afterEach (done) ->
      socketEventListeners = {}
      socketMock.end.reset()
      done()

    it 'passes the function string to the container', (done) ->
      executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'blScript'
        parsedJSONTask.blScript.should.eql testFunctionString
        done()

    it 'passes the request object to the container', (done) ->
      requestObject =
        body:
          test: 123
        headers:
          'x-kinvey-my-header': 'abc'

      executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, requestObject, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'request'
        parsedJSONTask.request.body.should.eql requestObject.body
        parsedJSONTask.request.headers.should.eql requestObject.headers
        done()

    it 'passes the response object to the container', (done) ->
      responseObject =
        body:
          test: 123
        headers:
          'x-kinvey-my-header': 'abc'

      executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, responseObject, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'response'
        parsedJSONTask.response.body.should.eql responseObject.body
        parsedJSONTask.response.headers.should.eql responseObject.headers
        done()

    it 'sets the request method to POST', (done) ->
      executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'method'
        parsedJSONTask.request.method.should.eql 'POST'
        done()

    it 'sets the request collection name to runFunction', (done) ->
      executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'collectionName'
        parsedJSONTask.request.collectionName.should.eql 'runFunction'
        done()

    it 'sets the targetFunction to onRequest', (done) ->
      executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'targetFunction'
        parsedJSONTask.targetFunction.should.eql 'onRequest'
        done()

    it 'sets the hookType to customEndpoint', (done) ->
      executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
        parsedJSONTask.should.have.property 'hookType'
        parsedJSONTask.hookType.should.eql 'customEndpoint'
        done()

    it 'loads common BL code if any is present in the specified folder', (done) ->
      options =
        quiet: true
        blRootPath: tempBlDirectoryName

      testModule.createClient options, (err, tester) ->
        if err then return done err

        commonFiles = ['var helped = false;\nvar helperFunction = function(){\n  helped = true;\n}',
                       'var helped2 = false;\nvar helperFunction2 = function(){\n  helped2 = true;\n}']

        for commonFileContents, i in commonFiles
          fileName = path.join options.blRootPath, config.directories.pathToCommonFiles, "testCommonBlCode#{i}.js"
          fs.writeFileSync fileName, commonFileContents

        executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, {}, {}, (parsedJSONTask) ->
          parsedJSONTask.blScript.should.eql commonFiles.join('\n;') + '\n;' + testFunctionString

          # cleanup
          commonFileDir = path.join tempBlDirectoryName, config.directories.pathToCommonFiles
          rimraf commonFileDir, () ->
            fs.mkdir commonFileDir
            done()

    it 'sets the request entityId to request.params.id or request.params.userid', (done) ->
      requestObject =
        params:
          id: 'testId'

      executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, requestObject, {}, (parsedJSONTask) ->
        parsedJSONTask.request.should.have.property 'entityId'
        parsedJSONTask.request.entityId.should.eql requestObject.params.id

        requestObject =
          params:
            userid: 'testUserId'

        executeTesterMethodThroughMock tester, 'runFunction', testFunctionString, requestObject, {}, (parsedJSONTask) ->
          parsedJSONTask.request.should.have.property 'entityId'
          parsedJSONTask.request.entityId.should.eql requestObject.params.userid
          done()
