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

class KinveyMockResponse
  response: null

  constructor: (fromJSON) ->
    @response = fromJSON ? {}

  setBody: (jsonBody) ->
    @response.body = jsonBody
    return this

  setHeaders: (headers) ->
    @response.headers = headers
    return this

  addHeader: (header, value) ->
    @response.headers ?= {}
    @response.headers[header] = value
    return this

  setStatusCode: (code) ->
    @response.status = code
    return this

  toJSON: () -> @response

module.exports = KinveyMockResponse
