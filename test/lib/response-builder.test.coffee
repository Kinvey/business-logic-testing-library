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
KinveyResponseObject = require '../../lib/response-builder.coffee'

describe 'Business Logic Tester / response object builder', () ->
  it 'tester.createResponseObject creates an instance of KinveyResponseObject', (done) ->
    tester.createResponseObject().should.be.an.instanceof KinveyResponseObject
    done()

  it 'starts as an empty response object', (done) ->
    responseObject = new KinveyResponseObject()
    responseObject.toJSON().should.eql {}
    done()

  it 'supports setting the response body', (done) ->
    body =
      test: 123

    responseObject = new KinveyResponseObject()
    responseObject.setBody body
    responseObject.toJSON().should.eql { body: body }
    done()

  it 'supports setting the response headers object', (done) ->
    headers =
      header1: 123
      header2: 'abc'

    responseObject = new KinveyResponseObject()
    responseObject.setHeaders headers
    responseObject.toJSON().should.eql { headers: headers }
    done()

  it 'addHeader adds a header if it does not already exist', (done) ->
    responseObject = new KinveyResponseObject()
    responseObject.addHeader 'header1', 123
    responseObject.toJSON().headers.should.eql { header1: 123 }
    done()

  it 'addHeader replaces an existing header', (done) ->
    headers =
      header1: 123
      header2: 'abc'

    responseObject = new KinveyResponseObject()
    responseObject.setHeaders headers
    responseObject.addHeader 'header1', 'abcdef'
    responseObject.toJSON().headers.should.eql { header1: 'abcdef', header2: 'abc' }
    done()

  it 'supports setting the response status code', (done) ->
    responseObject = new KinveyResponseObject()
    responseObject.setStatusCode 200
    responseObject.toJSON().status.should.eql 200
    done()
