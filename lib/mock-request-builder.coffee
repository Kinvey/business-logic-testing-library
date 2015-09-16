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

class KinveyMockRequest
  constructor: (fromJSON) ->
    @request = fromJSON ? {}

  setBody: (jsonBody) ->
    @request.body = jsonBody
    return this

  setHeaders: (headers) ->
    @request.headers = headers
    return this

  addHeader: (header, value) ->
    @request.headers ?= {}
    @request.headers[header] = value
    return this

  setParams: (params) ->
    @request.params = params
    return this

  addParam: (param, value) ->
    @request.params ?= {}
    @request.params[param] = value
    return this

  setAuthenticatedUsername: (username) ->
    @request.username = username
    return this

  setTempObjectStore: (objectStore) ->
    @request.tempObjectStore = objectStore
    return this

  toJSON: () -> @request

module.exports = KinveyMockRequest
