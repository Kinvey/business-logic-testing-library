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

request = require 'request'

makeProxyRequest = (url, port, jsonData, callback) ->
  request.post
    url: url
    port: port
    json: jsonData
    (err, res, body) ->
      callback err

class KinveyDataStore
  constructor: (configuration) ->
    unless configuration?.proxyPort? and configuration?.containerHostOrIP?
      throw new Error 'Configuration must contain proxyPort and containerHostOrIP properties'

    @containerHostOrIP = configuration.containerHostOrIP
    @proxyPort = configuration.proxyPort

  importCollectionData: (collectionName, jsonData = {}, clearBeforeInsert = false, callback) ->
    unless collectionName?
      return callback new Error 'Please specify the name of a collection into which data will be imported'

    if not callback? and typeof clearBeforeInsert is 'function'
      callback = clearBeforeInsert
      clearBeforeInsert = false

    collectionAccessURL = @containerHostOrIP + '/' + collectionName

    if clearBeforeInsert
      makeProxyRequest "#{collectionAccessURL}/remove", @proxyPort, {}, (err) =>
        if err? then return callback err
        makeProxyRequest "#{collectionAccessURL}/insert", @proxyPort, jsonData, callback
    else
      makeProxyRequest "#{collectionAccessURL}/insert", @proxyPort, jsonData, callback

  removeCollectionData: (collectionName, query = {}, callback) ->
    unless collectionName?
      return callback new Error 'Please specify the name of a collection into which data will be imported'

    collectionAccessURL = @containerHostOrIP + '/' + collectionName
    makeProxyRequest "#{collectionAccessURL}/remove", @proxyPort, query, callback

  getCollectionData: (collectionName, query = {}, callback) ->
    unless collectionName?
      return callback new Error 'Please specify the name of a collection into which data will be imported'

    collectionAccessURL = @containerHostOrIP + '/' + collectionName
    makeProxyRequest "#{collectionAccessURL}/find", @proxyPort, query, callback

module.exports = KinveyDataStore
