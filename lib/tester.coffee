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

fs = require 'fs'
net = require 'net'
path = require 'path'
uuid = require 'uuid'
clone = require 'clone'
config = require 'config'

configured = false
configuration = {}

sendJSONTaskToContainer = (jsonTask, callback) ->
  # TODO: Better TCP handling/error capturing
  containerSocket = net.createConnection configuration.containerPort, configuration.containerHostOrIP, () ->
    buffer = ''
    
    containerSocket.on 'data', (chunk) ->
      chunk = chunk.toString 'utf8'
      if chunk.indexOf('\n') is -1
        buffer += chunk
        return

      buffer += chunk.slice(0, chunk.indexOf('\n')-1)

      try
        parsedData = JSON.parse buffer
      catch e
        e.message = 'Could not parse JSON response. ' + e.message
        return callback e

      if not parsedData?.taskId and parsedData?.metadata?.taskId
        parsedData.taskId = parsedData.metadata.taskId

      containerSocket.end()

      # TODO: Figure out how errors are sent back
      if parsedData?.isError?
        return callback parsedData

      callback null, parsedData

    containerSocket.write JSON.stringify jsonTask
    containerSocket.write '\n'

getCommonBLCode = () ->
  try
    fullPathToCommonFiles = path.join configuration.blRootPath, config.directories.pathToCommonFiles
    commonFiles = fs.readdirSync fullPathToCommonFiles
  catch error
    return '' # if there are no common files, we're done

  commonBL = ''
  for fileName in commonFiles
    commonBL += fs.readFileSync path.join(fullPathToCommonFiles, fileName), { encoding: 'utf8' }
    commonBL += '\n;' # delimit content of files
  return commonBL

runBLCodeString = (blCodeString, isCollectionHook, collectionOrEndpointName, blFunctionName, request, response, callback) ->
  if request? then request = clone request
  if response? then response = clone response

  # request defaults
  request ?= {}
  request.headers ?= {}
  request.body ?= {}
  request.params ?= {}
  request.tempObjectStore ?= {}
  request.username ?= 'testUsername'
  request.entityId = request.params.id ? request.params.userid

  unless request.method?
    switch blFunctionName
      when 'onRequest', 'onPreSave', 'onPostSave' then request.method = 'POST'
      when 'onPreFetch', 'onPostFetch' then request.method = 'GET'
      when 'onPreDelete', 'onPostDelete' then request.method = 'DELETE'

  unless request.collectionName?
    request.collectionName = collectionOrEndpointName

  # response defaults
  response ?= {}
  response.status ?= 0
  response.headers ?= {}
  response.body ?= {}

  task =
    appId: configuration.environmentID
    appMetadata:
      _id: configuration.environmentID
      appsecret: configuration.appSecret
      mastersecret: configuration.masterSecret
    blScript: blCodeString
    request: request
    response: response
    targetFunction: blFunctionName
    taskId: uuid()

  # TO BE REMOVED (once it's gone from core/api)
  task.collectionName = collectionOrEndpointName
  if isCollectionHook
    task.hookType = 'collectionHook'
  else
    task.hookType = 'customEndpoint'
  # /TO BE REMOVED

  sendJSONTaskToContainer task, (err, jsonResponseFromBL) ->
    if err then return callback err

    # jsonResponseFromBL is the response emitted from the business-logic-api module.
    # it contains 'metadata', 'request' and 'response' properties, each containing JSON.
    callback null, jsonResponseFromBL

getCodeStringFromFilesystem = (subfolderName, fileName, callback) ->
  try
    codeString = getCommonBLCode()
    codeString += fs.readFileSync path.join(configuration.blRootPath, subfolderName, fileName + '.js'), { encoding: 'utf8' }
  catch error
    error.name = 'BLFileNotFoundError' # change the name, making the error a bit more descriptive
    throw error

  return codeString

module.exports =
  configure: (options = {}) ->
    configuration = {}

    if not options.blRootPath? or not fs.existsSync options.blRootPath
      unless options.quiet
        console.log 'WARNING: blRootPath not specified or path does not exist. You will not be able to run BL code from your BL files.'

    unless options.environmentID?
      options.environmentID = config.environmentID
      unless options.quiet
        console.log "WARNING: environmentID not specified, running BL in the context of the default #{options.environmentID} environment."

    unless options.containerHostOrIP?
      options.containerHostOrIP = config.containerHostOrIP
      unless options.quiet
        console.log "WARNING: containerHostOrIP not specified, using default of #{options.containerHostOrIP}."

    unless options.containerPort?
      options.containerPort = config.containerPort
      unless options.quiet
        console.log "WARNING: containerPort not specified, using default of #{options.containerPort}."

    configuration.containerHostOrIP = options.containerHostOrIP
    configuration.containerPort = options.containerPort

    configuration.environmentID = options.environmentID
    configuration.appSecret = options.appSecret ? "#{options.environmentID}-app-secret"
    configuration.masterSecret = options.masterSecret ? "#{options.environmentID}-master-secret"

    configuration.blRootPath = options.blRootPath
    configured = true
    return

  runCollectionHook: (collectionName, blFunctionName, request, response, callback) ->
    unless configured
      error = new Error "Please call the 'configure' method before attempting to run BL code"
      error.name = 'BLConfiguraionRequiredError'
      return callback error

    try
      codeString = getCodeStringFromFilesystem config.directories.pathToCollections + '/' + collectionName, blFunctionName
    catch err
      return callback err

    runBLCodeString codeString, true, collectionName, blFunctionName, request, response, callback

  runCustomEndpoint: (endpointName, request, response, callback) ->
    unless configured
      error = new Error "Please call the 'configure' method before attempting to run BL code"
      error.name = 'BLConfiguraionRequiredError'
      return callback error

    try
      codeString = getCodeStringFromFilesystem 'endpoints', endpointName
    catch err
      return callback err

    runBLCodeString codeString, false, endpointName, 'onRequest', request, response, callback

  runFunction: (codeToRun, request, response, callback) ->
    unless configured
      error = new Error "Please call the 'configure' method before attempting to run BL code"
      error.name = 'BLConfiguraionRequiredError'
      return callback error

    switch typeof codeToRun
      when 'string' then codeString = codeToRun
      when 'function' then codeString = Function::toString(codeToRun)
      else return callback new Error 'codeToRun must be a function or a stringified function'

    codeString = getCommonBLCode() + codeString

    runBLCodeString codeString, false, 'runFunction', 'onRequest', request, response, callback
