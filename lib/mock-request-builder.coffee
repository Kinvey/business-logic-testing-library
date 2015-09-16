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
