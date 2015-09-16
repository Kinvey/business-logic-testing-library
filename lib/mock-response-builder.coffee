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
