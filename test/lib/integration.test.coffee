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
testModule = require '../../lib/tester'

describe 'Business Logic Tester / integration tests', () ->
  tester = null

  before (done) ->
    console.log '================================================================================'
    console.log ' This test assumes that the kinvey tester docker image is running, and that the'
    console.log ' docker hostname is either \'localhost\' or specified in the $DOCKER_HOST env var'
    console.log '================================================================================'
    testModule.createClient { quiet: true }, (err, testerInstance) ->
      if err then return done err
      tester = testerInstance
      done()

  it 'can run a function and return response data', (done) ->
    functionString = 'function onRequest(request, response, modules){ response.body = { testPassed: true }; response.complete(); }'
    tester.runFunction functionString, {}, {}, (err, responseFromBL) ->
      should.not.exist err
      responseFromBL.response.should.have.properties 'body', 'statusCode'
      responseFromBL.response.statusCode.should.eql 200
      responseFromBL.response.body.should.have.property 'testPassed'
      responseFromBL.response.body.testPassed.should.be.true
      done()
