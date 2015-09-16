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
tester = require '../../lib/tester'
KinveyMockRequest = require '../../lib/mock-request-builder.coffee'

describe 'Business Logic Tester / request object builder', () ->
  it 'tester.createMockRequest creates an instance of KinveyMockRequest', (done) ->
    tester.createMockRequest().should.be.an.instanceof KinveyMockRequest
    done()

  it 'starts as an empty request object', (done) ->
    requestObject = new KinveyMockRequest()
    requestObject.toJSON().should.eql {}
    done()

  it 'supports setting the request body', (done) ->
    body =
      test: 123

    requestObject = new KinveyMockRequest()
    requestObject.setBody body
    requestObject.toJSON().should.eql { body: body }
    done()

  it 'supports setting the request headers object', (done) ->
    headers =
      header1: 123
      header2: 'abc'

    requestObject = new KinveyMockRequest()
    requestObject.setHeaders headers
    requestObject.toJSON().should.eql { headers: headers }
    done()

  it 'addHeader adds a header if it does not already exist', (done) ->
    requestObject = new KinveyMockRequest()
    requestObject.addHeader 'header1', 123
    requestObject.toJSON().headers.should.eql { header1: 123 }
    done()

  it 'addHeader replaces an existing header', (done) ->
    headers =
      header1: 123
      header2: 'abc'

    requestObject = new KinveyMockRequest()
    requestObject.setHeaders headers
    requestObject.addHeader 'header1', 'abcdef'
    requestObject.toJSON().headers.should.eql { header1: 'abcdef', header2: 'abc' }
    done()

  it 'can set the request params object', (done) ->
    params =
      param1: 123
      param2: 'abc'

    requestObject = new KinveyMockRequest()
    requestObject.setParams params
    requestObject.toJSON().should.eql { params: params }
    done()

  it 'addParam adds a param if it does not already exist', (done) ->
    requestObject = new KinveyMockRequest()
    requestObject.addParam 'param1', 123
    requestObject.toJSON().params.should.eql { param1: 123 }
    done()

  it 'addParam replaces an existing param', (done) ->
    params =
      param1: 123
      param2: 'abc'

    requestObject = new KinveyMockRequest()
    requestObject.setParams params
    requestObject.addParam 'param1', 'abcdef'
    requestObject.toJSON().params.should.eql { param1: 'abcdef', param2: 'abc' }
    done()

  it 'supports setting the authenticated username', (done) ->
    requestObject = new KinveyMockRequest()
    requestObject.setAuthenticatedUsername 'testUsername'
    requestObject.toJSON().username.should.eql 'testUsername'
    done()

  it 'supports setting the temp object store', (done) ->
    tempObjectStore =
      test: 0.9
      test2: 'abc'

    requestObject = new KinveyMockRequest()
    requestObject.setTempObjectStore tempObjectStore
    requestObject.toJSON().tempObjectStore.should.eql tempObjectStore
    done()
