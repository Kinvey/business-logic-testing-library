#
# Copyright 2016 Kinvey, Inc.
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

should = require 'should'
sinon = require 'sinon'
proxyquire = require 'proxyquire'
KinveyBusinessLogicClient = require '../../lib/tester'

describe 'Business Logic Tester / data store', () ->
  configuration =
    containerHostOrIP: 'testHost'
    proxyPort: 54231

  KinveyDataStore = null

  mockRequest =
    post: sinon.stub()


  baseUrl = "http://#{configuration.containerHostOrIP}:#{configuration.proxyPort}"

  before (done) ->
    KinveyDataStore = proxyquire '../../lib/data-store', { request: mockRequest }
    done()

  beforeEach (done) ->
    mockRequest.post.reset()
    mockRequest.post.callsArg 1
    done()

  it 'KinveyBusinessLogicClient.dataStore contains an instance of KinveyDataStore', (done) ->
    KinveyBusinessLogicClient.createClient { quiet: true }, (err, testerInstance) ->
      should.not.exist err
      testerInstance.dataStore.should.be.an.instanceof require('../../lib/data-store')
      done()

  it 'exposes methods to import, remove and retrieve collection data', (done) ->
    dataStore = new KinveyDataStore configuration
    dataStore.should.have.properties ['importCollectionData', 'removeCollectionData', 'getCollectionData']
    done()

  describe 'importing collection data', ->
    it 'returns an error if a collection name is not specified', (done) ->
      dataStore = new KinveyDataStore configuration
      dataStore.importCollectionData null, null, null, (err) ->
        should.exist err
        done()

    it 'submits an insert request to the proxy, containing the specified data', (done) ->
      dataToInsert = [ { a: 1 }, { b: 2 } ]

      dataStore = new KinveyDataStore configuration
      dataStore.importCollectionData 'testCollection', dataToInsert, false, (err) ->

        should.not.exist err
        postArgs = mockRequest.post.args[0][0]
        postArgs.url.should.eql baseUrl + '/collectionAccess/testCollection/insert'
        postArgs.json.should.eql { entity: dataToInsert }
        done()

    it 'if data is not specified, inserts an empty object', (done) ->
      dataStore = new KinveyDataStore configuration
      dataStore.importCollectionData 'testCollection', null, false, (err) ->
        should.not.exist err
        postArgs = mockRequest.post.args[0][0]
        postArgs.json.should.eql { entity: { } }
        done()

    it 'supports the clearBeforeInsert parameter', (done) ->
      dataToInsert = [ { a: 1 }, { b: 2 } ]

      dataStore = new KinveyDataStore configuration
      dataStore.importCollectionData 'testCollection', dataToInsert, true, (err) ->
        should.not.exist err
        removeArgs = mockRequest.post.args[0][0]
        removeArgs.url.should.eql baseUrl + '/collectionAccess/testCollection/remove'
        removeArgs.json.should.eql { query: { } }

        insertArgs = mockRequest.post.args[1][0]
        insertArgs.url.should.eql baseUrl + '/collectionAccess/testCollection/insert'
        insertArgs.json.should.eql { entity: dataToInsert }
        done()

    it 'if clearBeforeInsert is not specified, defaults to false', (done) ->
      dataToInsert = [ { a: 1 }, { b: 2 } ]

      dataStore = new KinveyDataStore configuration
      dataStore.importCollectionData 'testCollection', dataToInsert, (err) ->
        should.not.exist err
        insertArgs = mockRequest.post.args[0][0]
        insertArgs.url.should.eql baseUrl + '/collectionAccess/testCollection/insert'
        insertArgs.json.should.eql { entity: dataToInsert }
        done()

  describe 'removing collection data', ->
    it 'returns an error if a collection name is not specified', (done) ->
      dataStore = new KinveyDataStore configuration
      dataStore.removeCollectionData null, null, (err) ->
        should.exist err
        done()

    it 'submits an remove request to the proxy, containing the specified query', (done) ->
      query =
        _id: 'testId'

      dataStore = new KinveyDataStore configuration
      dataStore.removeCollectionData 'testCollection', query, (err) ->
        should.not.exist err
        postArgs = mockRequest.post.args[0][0]
        postArgs.url.should.eql baseUrl + '/collectionAccess/testCollection/remove'
        postArgs.json.should.eql { query: query }
        done()

    it 'if query is not specified, an empty query is used', (done) ->
      dataStore = new KinveyDataStore configuration
      dataStore.removeCollectionData 'testCollection', null, (err) ->
        should.not.exist err
        postArgs = mockRequest.post.args[0][0]
        postArgs.json.should.eql { query: { } }
        done()

  describe 'retrieving collection data', ->
    it 'returns an error if a collection name is not specified', (done) ->
      dataStore = new KinveyDataStore configuration
      dataStore.getCollectionData null, null, (err) ->
        should.exist err
        done()

    it 'submits an remove request to the proxy, containing the specified query', (done) ->
      query =
        _id: 'testId'

      dataStore = new KinveyDataStore configuration
      dataStore.getCollectionData 'testCollection', query, (err) ->
        should.not.exist err
        postArgs = mockRequest.post.args[0][0]
        postArgs.url.should.eql baseUrl + '/collectionAccess/testCollection/find'
        postArgs.json.should.eql { query: query }
        done()

    it 'if query is not specified, an empty query is used', (done) ->
      dataStore = new KinveyDataStore configuration
      dataStore.getCollectionData 'testCollection', null, (err) ->
        should.not.exist err
        postArgs = mockRequest.post.args[0][0]
        postArgs.json.should.eql { query: { } }
        done()
