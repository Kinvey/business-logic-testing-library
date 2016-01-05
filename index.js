/**
 * Copyright 2016 Kinvey, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Strict mode.
'use strict';

// Standard lib.
var path = require('path');

// Package modules.
require('coffee-script/register');

// Configure.
process.env.NODE_CONFIG_DIR = path.join(__dirname, 'config/');

// Exports.
module.exports      = require('./lib/tester');
module.exports.util = require('./lib/util');
module.exports.ENTRY_POINT = 'index';