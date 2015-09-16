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

# Package modules.
async  = require 'async'
Docker = require 'dockerode'

# Local modules.
tester = require './tester.coffee'

# Configure.
docker = new Docker()

# Helper to start a container with the specified Docker image.
startDockerContainer = (imageName, callback) ->
  # Determine if a container with the specified image is already running.
  docker.listContainers (err, containers) ->
    if err? then callback err
    else # See if the container is already running.
      for container in containers
        if imageName is container.Image
          return callback() # Already running, stop.

      # No container available, create a new one.
      async.waterfall [
        # Pull latest image, and process pull stream.
        docker.pull.bind docker, "#{imageName}:latest"
        docker.modem.followProgress.bind docker.modem

        # Create and start a new container with the pulled image.
        (data, callback) -> docker.createContainer { Image: imageName }, callback
        (container, callback) -> container.start { PublishAllPorts: true }, callback
      ], callback

# Utility to set-up test suite.
setup = (options, callback) ->
  options.quiet = true # Mute tester warnings.

  # Run.
  async.series {
    # Ensure Docker is ready.
    docker: (callback) ->
      docker.ping (err) ->
        if err? then err.message = 'Failed to reach Docker. Are you sure Docker is running properly?'
        callback err # Continue.

    # Set-up Docker containers.
    proxy  : startDockerContainer.bind null, 'kinvey/bl-mock-proxy'
    runner : startDockerContainer.bind null, 'kinvey/blrunner'

    # Set-up tester.
    client: tester.createClient.bind tester, options
  }, (err, results) ->
    # Pass the tester client back to the test suite.
    # TODO Replace the timeout with something more reliable.
    setTimeout () ->
      callback err, results.client
    , 1000

# Utility to teardown test suite.
teardown = (options, callback) ->
  callback() # Do nothing.

# Exports.
module.exports = { setup: setup, teardown: teardown }