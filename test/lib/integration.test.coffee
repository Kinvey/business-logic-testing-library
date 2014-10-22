# Copyright (c) 2014, Kinvey, Inc. All rights reserved.
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

should = require 'should'
tester = require '../../lib/tester'

# match an IP (any consecutive combination of numbers and dots) in the DOCKER_HOST environment variable
dockerHostname = process.env.DOCKER_HOST.match(/([\d\.+]+)/)[1]

describe 'Business Logic Tester / integration tests', () ->
  before (done) ->
    options =
      quiet: true
      containerPort: 45050
      containerHostOrIP: dockerHostname

    tester.configure options
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
