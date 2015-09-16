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

should = require 'should'
tester = require '../../lib/tester'
KinveyMockResponse = require '../../lib/mock-response-builder.coffee'

describe 'Business Logic Tester / response object builder', () ->
  it 'tester.createMockResponse creates an instance of KinveyMockResponse', (done) ->
    tester.createMockResponse().should.be.an.instanceof KinveyMockResponse
    done()

  it 'starts as an empty response object', (done) ->
    responseObject = new KinveyMockResponse()
    responseObject.toJSON().should.eql {}
    done()

  it 'supports setting the response body', (done) ->
    body =
      test: 123

    responseObject = new KinveyMockResponse()
    responseObject.setBody body
    responseObject.toJSON().should.eql { body: body }
    done()

  it 'supports setting the response headers object', (done) ->
    headers =
      header1: 123
      header2: 'abc'

    responseObject = new KinveyMockResponse()
    responseObject.setHeaders headers
    responseObject.toJSON().should.eql { headers: headers }
    done()

  it 'addHeader adds a header if it does not already exist', (done) ->
    responseObject = new KinveyMockResponse()
    responseObject.addHeader 'header1', 123
    responseObject.toJSON().headers.should.eql { header1: 123 }
    done()

  it 'addHeader replaces an existing header', (done) ->
    headers =
      header1: 123
      header2: 'abc'

    responseObject = new KinveyMockResponse()
    responseObject.setHeaders headers
    responseObject.addHeader 'header1', 'abcdef'
    responseObject.toJSON().headers.should.eql { header1: 'abcdef', header2: 'abc' }
    done()

  it 'supports setting the response status code', (done) ->
    responseObject = new KinveyMockResponse()
    responseObject.setStatusCode 200
    responseObject.toJSON().status.should.eql 200
    done()
