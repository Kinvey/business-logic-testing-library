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
