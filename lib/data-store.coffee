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

request = require 'request'

makeProxyRequest = (url, jsonData, callback) ->
  request.post
    url: url
    json: jsonData
    (err, res, body) ->
      if 2 is parseInt res?.statusCode / 100, 10
        callback err, body
      else
        callback err

class KinveyDataStore
  constructor: (configuration) ->
    unless configuration?.proxyPort? and configuration?.containerHostOrIP?
      throw new Error 'Configuration must contain proxyPort and containerHostOrIP properties'

    @base = "http://#{configuration.containerHostOrIP}:#{configuration.proxyPort}"

  importCollectionData: (collectionName, jsonData = {}, clearBeforeInsert = false, callback) ->
    unless collectionName?
      return callback new Error 'Please specify the name of a collection into which data will be imported'

    if not callback? and typeof clearBeforeInsert is 'function'
      callback = clearBeforeInsert
      clearBeforeInsert = false

    collectionAccessURL = @base + '/collectionAccess/' + collectionName

    if clearBeforeInsert
      makeProxyRequest "#{collectionAccessURL}/remove", { query: { } }, (err) ->
        if err? then return callback err
        makeProxyRequest "#{collectionAccessURL}/insert", { entity: jsonData }, callback
    else
      makeProxyRequest "#{collectionAccessURL}/insert", { entity: jsonData }, callback

  removeCollectionData: (collectionName, query = {}, callback) ->
    unless collectionName?
      return callback new Error 'Please specify the name of a collection into which data will be imported'

    collectionAccessURL = @base + '/collectionAccess/' + collectionName
    makeProxyRequest "#{collectionAccessURL}/remove", { query: query }, callback

  getCollectionData: (collectionName, query = {}, callback) ->
    unless collectionName?
      return callback new Error 'Please specify the name of a collection into which data will be imported'

    collectionAccessURL = @base + '/collectionAccess/' + collectionName
    makeProxyRequest "#{collectionAccessURL}/find", { query: query }, callback

module.exports = KinveyDataStore
