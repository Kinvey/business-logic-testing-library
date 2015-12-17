# Helper module for testing Kinvey Business Logic

This module provides an easy way to connect to a Kinvey Business Logic (BL) instance running on docker. It is up to the user to download, configure and start the docker image itself before running code using this module. Two [utility](#Utilities) functions are provided to automate setting up the docker image.

The module serves two purposes:

1. Integrate with the Kinvey BL CLI tool to support offline testing of BL code.
2. Allow a developer to run a custom BL function in order to test its validity and behavior.

In order to use the module, you will first need to create and configure a client instance, and then call one of its API methods. These steps are explained in more detail below.

## Table of contents

* [Methods](#usage)
  * [createMockRequest](#createmockrequestfromjson)
  * [createMockResponse](#createmockresponsefromjson)
  * [createClient](#createclientjsonconfiguration-callback)
    * [runCollectionHook](#runcollectionhookcollectionname-blfunctionname-requestobject-responseobject-callback)
    * [runCustomEndpoint](#runcustomendpointendpointname-requestobject-responseobject-callback)
    * [runFunction](#runfunctioncodetorun-requestobject-responseobject-callback)
    * [dateStore](#datastore)
      * [importCollectionData](#importcollectiondatacollectionname-jsondata-clearbeforeinsert-callback)
      * [removeCollectionData](#removecollectiondatacollectionname-query-callback)
      * [getCollectionData](#getcollectiondatacollectionname-query-callback)
* [Common code](#common-code)
* [Helpers](#helpers)
  * [Mock request builder](#mock-request-builder)
    * [Usage and constructor](#usage-and-constructor)
    * [Chaining](#chaining)
    * [setBody](#setbodyjsonobject)
    * [setHeaders](#setheadersjsonobject)
    * [addHeader](#addheadername-contents)
    * [setParams](#setparamsjsonobject)
    * [addParam](#addparamname-contents)
    * [setAuthenticatedUsername](#setauthenticatedusernameusername)
    * [setTempObjectStore](#settempobjectstorejsonobject)
    * [toJSON](#tojson)
  * [Mock response builder](#mock-response-builder)
    * [Usage and constructor](#usage-and-constructor-1)
    * [Chaining](#chaining-1)
    * [setBody](#setbodyjsonobject-1)
    * [setHeaders](#setheadersjsonobject-1)
    * [addHeader](#addheadername-contents-1)
    * [setStatusCode](#setstatuscodecode)
    * [toJSON](#tojson-1)
* [Utilities](#utilities)
  * [Setup](#setup)
  * [Teardown](#teardown)

## Usage

The module exposes the following API:

### createMockRequest(fromJSON)

Create an instance of the request builder, which can be used to construct a request object to pass to the *run...* function described above. For more details, take a look at the [request builder documentation](#mock-request-builder) below.

### createMockResponse(fromJSON)

Create an instance of the response builder, which can be used to construct a response object to pass to the *run...* function described above. For more details, take a look at the [response builder documentation](#mock-response-builder) below.

### createClient(jsonConfiguration, callback)

Create a client instance, which will be able to communicate with the Business Logic docker container. The `jsonConfiguration` parameter allows you to *optionally* specify configuration options as a JSON object. The structure of the JSON object supports the following properties:

| property name | type | description | default value |
| ------------- | ---- | ----------- | ------------- |
| blRootPath | string | the path to the root of the `business-logic` folder created by using the BL CLI tool | N/A |
| environmentID | string | the ID of the environment to simulate | 'BusinessLogicTest' |
| appSecret | string | the app secret of the simulated environment | '_environmentID_-app-secret' |
| masterSecret | string | the master secret of the simulated environment | '_environmentID_-master-secret' |
| containerHostOrIP | string | the hostname or IP address of the docker container running the BL instance | $DOCKER_HOST or 'localhost' |
| runnerPort | number | the port exposed by the instance of the Kinvey BL running in the docker container | 7000 |
| proxyPort | number | the port exposed by the instance of the Kinvey proxy running in the docker container | 2845 |

*Note* that you do not need to specify all values. Generally, you will want to configure the testing module with the `blRootPath` parameter. The environment-specific configuration parameters are provided as an option in case your BL code relies on this information. The other parameters, which are related to the docker container, will normally be obtained automatically (`containerHostOrIP` will default to the `DOCKER_HOST` environment variable, if defined, and to `localhost` otherwise; `runnerPort` and `proxyPort` will be obtained by inspecting the running docker container), and are only provided here as optional overrides.

The callback function should accept two arguments: an error (which will be set to null if no error has occurred), and an instance of the client.

The client instance created using this method exposes the following methods, which are described in detail below:

* [runCollectionHook](#runcollectionhookcollectionname-blfunctionname-requestobject-responseobject-callback)
* [runCustomEndpoint](#runcustomendpointendpointname-requestobject-responseobject-callback)
* [runFunction](#runfunctioncodetorun-requestobject-responseobject-callback)

**Example**

```javascript
var tester = require('business-logic-testing-library');

var options = {
  blRootPath: '/Users/JohnDoe/Documents/kinvey/business-logic',
  environmentID: 'MyAwesomeEnvironment'
}

tester.createClient(options, function(err, client) {
  if (err) {
    // handle error
  }

  client.runFunction( ... );
});
```

#### runCollectionHook(collectionName, blFunctionName, requestObject, responseObject, callback)

Run the code contained within a collection hook. This method relies on the existence of the collection hook .js file within the BL CLI folder structure. For example, if your collection is called `MyCollection`, and you are running an post-fetch hook, the tester will look for the code at `_blRootPath_/collections/MyCollection/onPostFetch.js` (where `_blRootPath_` is the path to the root of the BL folder structure, as specified in the options to the [createClient](createclientjsonconfiguration-callback) method).

##### Arguments

| name | type | description |
| ---- | ---- | ----------- |
| collectionName | string | the name of the collection associated with the hook |
| blFunctionName | string | the hook function to call. One of: `onPreSave`, `onPostSave`, `onPreFetch`, `onPostFetch`, `onPreDelete`, `onPostDelete` |
| requestObject | JSON or mock-request-builder instance | the object made available to the BL code through the `request` variable |
| responseObject | JSON or mock-response-builder instance | the object made available to the BL code through the `response` variable |
| callback | function | the function that will be called when the BL code has finished executing. This function should accept two parameters: `error` and `blResult`. The response will be a JSON object containing `metadata`, `request` and `response` properties. |

##### Example

```javascript
var requestObject = {
  body: {
    _id: 'abcd'
  },
  headers: {
    'x-kinvey-api-version': 3
  },
  username: 'foobar'
};

var responseObject = {};

client.runCollectionHook('MyCollection', 'onPreSave', requestObject, responseObject, function(error, blResult) {
  if (error) {
    // handle the error
  }
  else {
    console.log("Received response with body:", blResult.response.body);
  }
});
```


#### runCustomEndpoint(endpointName, requestObject, responseObject, callback)

Run the code contained within a custom endpoint. This method relies on the existence of the endpoint .js file within the BL CLI folder structure. For example, if your endpoint is called `myEndpoint`, the tester will look for the code at `_blRootPath_/endpoints/myEndpoint.js` (where `_blRootPath_` is the path to the root of the BL folder structure, as specified in the options to the [createClient](createclientjsonconfiguration-callback) method).

##### Arguments

| name | type | description |
| ---- | ---- | ----------- |
| endpointName | string | the name of the endpoint you wish to run |
| requestObject | JSON or mock-request-builder instance | the object made available to the BL code through the `request` variable |
| responseObject | JSON or mock-response-builder instance | the object made available to the BL code through the `response` variable |
| callback | function | the function that will be called when the BL code has finished executing. This function should accept two parameters: `error` and `blResult`. The response will be a JSON object containing `metadata`, `request` and `response` properties. |

##### Example

```javascript
var requestObject = {
  body: {
    _id: 'abcd'
  },
  headers: {
    'x-kinvey-api-version': 3
  },
  username: 'foobar'
};

var responseObject = {};

client.runCustomEndpoint('myEndpoint', requestObject, responseObject, function(error, blResult) {
  if (error) {
    // handle the error
  }
  else {
    console.log("Received response with body:", blResult.response.body);
  }
});
```


#### runFunction(codeToRun, requestObject, responseObject, callback)

Run code from a function or a function string. The function must match the custom endpoint signature: `function onRequest(request, response, modules){ ... }`.

##### Arguments

| name | type | description |
| ---- | ---- | ----------- |
| codeToRun | function or string | code you wish to run |
| requestObject | JSON or mock-request-builder instance | the object made available to the BL code through the `request` variable |
| responseObject | JSON or mock-response-builder instance | the object made available to the BL code through the `response` variable |
| callback | function | the function that will be called when the BL code has finished executing. This function should accept two parameters: `error` and `blResult`. The response will be a JSON object containing `metadata`, `request` and `response` properties. |

##### Example

```javascript
var requestObject = {
  body: {
    _id: 'abcd'
  },
  headers: {
    'x-kinvey-api-version': 3
  },
  username: 'foobar'
};

var responseObject = {};

var helloWorld = function onRequest(request, response, modules) {
  response.body = { 'hello': 'world' };
  response.complete();
};

client.runFunction(helloWorld, requestObject, responseObject, function(error, blResult) {
  if (error) {
    // handle the error
  }
  else {
    console.log("Received response with body:", blResult.response.body);
  }
});
```

#### dataStore

The testing container uses [TingoDB](http://github.com/sergeyksv/tingodb) to create a simulated data store and allow your Business Logic code to interact with data through the `collectionAccess` module, much like it normally would. While there are some differences between the API exposed by TingoDB and the one exposed by production instances of Kinvey (which use MongoDB), these are minor, and should allow you to simulate almost everything you wish. If you were to encounter a corner case which is handled differently by TingoDB and MongoDB, please first check the TingoDB documentation before contacting Kinvey support.

*Please note* that this data store exists **entirely offline**, within the docker container running on your local machine, and is not connected to Kinvey's production data store.

The data store exposes several methods, which can be accessed through the client's `dataStore` object. Detailed information on these methods and examples of their use can be found below.

##### importCollectionData(collectionName, jsonData, clearBeforeInsert, callback)

Allows you to import JSON data into a named collection.

The `jsonData` parameter can contain a JSON object or an array of JSON objects.

The `clearBeforeInsert` parameter, which defaults to `false`, will remove the contents of the collection before importing the data. This may be useful if you wish to be sure that your test environment starts with the same data every time.

The callback function should accept a single error argument, which will be set to null if no error has occurred.

**Example**

```javascript
var tester = require('business-logic-testing-library');
var options = { ... };

tester.createClient(options, function(err, client) {
  if (err) {
    // handle error
  }

  var data = [{
      'first_name': 'John',
      'last_name': 'Doe'
    },
    {
      'first_name': 'Chuck',
      'last_name': 'Norris'
    }];

  client.dataStore.importCollectionData('customers', data, true, function(err) {
    if (err) {
      // handle error
    }

    ...
  });
});
```

##### removeCollectionData(collectionName, query, callback)

Allows you to remove entities from a named collection.

The `query` parameter should contain a MongoDB-style JSON query (for more details on constructing these types of queries, please check [MongoDB's site](http://docs.mongodb.org/manual/tutorial/query-documents/)).

The callback function should accept a single error argument, which will be set to null if no error has occurred.

**Example**

```javascript
var tester = require('business-logic-testing-library');
var options = { ... };

tester.createClient(options, function(err, client) {
  if (err) {
    // handle error
  }

  client.dataStore.removeCollectionData('customers', { 'first_name': { '$in': ['John', 'Chuck'] } }, function(err) {
    if (err) {
      // handle error
    }

    ...
  });
});
```

##### getCollectionData(collectionName, query, callback)

Allows you to retrieve entities from a named collection.

The `query` parameter should contain a MongoDB-style JSON query (for more details on constructing these types of queries, please check [MongoDB's site](http://docs.mongodb.org/manual/tutorial/query-documents/)).

The callback function should accept an error argument, which will be set to null if no error has occurred, and a second argument which will contain the retrieved JSON data.

**Example**

```javascript
var tester = require('business-logic-testing-library');
var options = { ... };

tester.createClient(options, function(err, client) {
  if (err) {
    // handle error
  }

  client.dataStore.getCollectionData('customers', { 'first_name': { '$in': ['John', 'Chuck'] } }, function(err, entities) {
    if (err) {
      // handle error
    }

    // at this point, the entities variable contains the results of execuring the query against the testing container's data store
  });
});
```

## Common code

All methods support common code defined within the BL CLI folder structure. When any of the `run...` methods described above are called, the testing module will read the contents of any common code files contained within the `_blRootPath_/common/` directory (where `_blRootPath_` is the path to the root of the BL folder structure, as specified in the options to the [createClient](createclientjsonconfiguration-callback) method). Any common code will be executed before running your collection hook/custom endpoint/function code.

##### Example



```javascript
/**** contents of _blRootPath/common/helperFunctions.js ***/
var timesTwo = function(number) {
  return (number * 2);
}
/**** end of helperFunctions.js ****/


/**** contents of _blRootPath/custom/myEndpoint.js ***/
function onRequest(request, response, modules) {
  response.body = {
    multipliedNumber: timesTwo(parseInt(request.body.number))
  };
  response.complete();
};
/**** end of myEndpoint.js ***/


// testing code
var requestObject = {
  body: {
    number: 4
  }
};

client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {
  if (error) {
    console.log("Error encountered! details:", error);
  }
  else {
    console.log("4 * 2 is", blResult.response.body.multipliedNumber);
  }
});
```

## Helpers

### Mock request builder

In order to run business logic using any of the *run...* methods listed on this page, you must pass in a request object. This object contains data and metadata about the (simulated) incoming HTTP request (FROM the client TO Kinvey), and is used to pass necessary information to the testing framework. In order to simplify the use of this object, you can use the `mock-request-builder` helper module, which exposes an API to create a request object.

#### Usage and constructor

To use the request builder, require the testing module, and then call its createMockRequest method. The constructor optionally accepts a JSON object containing initial values.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var options = { ... };

var requestObject = tester.createMockRequest({ body: { testing: true }});

tester.createClient(options, function(err, client) {
  if (err) {
    // handle error
  }

  client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
});
```

#### Chaining

With the exception of `toJSON`, all methods of the request builder return the instance of the builder, allowing for chained method calls. For example:

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createMockRequest();
requestObject.setBody({ testing: true }).addHeader('x-kinvey-api-version', 3);
```

#### setBody(jsonObject)

Set the `body` property of the request object, which corresponds to the body of the incoming HTTP request. Accepts a JSON object.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createMockRequest();

requestObject.setBody({ testing: true });

client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### setHeaders(jsonObject)

Set the `headers` property of the request object, which corresponds to the headers of the incoming HTTP request. Accepts a JSON object in which keys are header names and values are header contents.

##### Example

```javascript
var requestObject = tester.createMockRequest();

requestObject.setHeaders({ 'x-kinvey-api-version': 3 });

client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### addHeader(name, contents)

Add a header to the `headers` property of the request object, which corresponds to the headers of the incoming HTTP request. Accepts the name of a header, and its contents. If a header by that name already exists, this method will replace its contents.

##### Example

```javascript
var requestObject = tester.createMockRequest();

requestObject.addHeader('x-kinvey-api-version', 3);

client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### setParams(jsonObject)

Set the `params` property of the request object, which corresponds to the parameters of the incoming HTTP request. Accepts a JSON object in which keys are parameter names and values are their contents. For `GET`, `PUT`, and `DELETE` requests, you can use `id` (not: `_id`) as parameter name to specify an entity id. For `POST`, specify an `_id` in the [request body](#example).

##### Example

```javascript
var requestObject = tester.createMockRequest();

requestObject.setParams({ 'query': { myField: 'myValue' }});

client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```


#### addParam(name, contents)

Add a parameter to the `params` property of the request object, which corresponds to the parameters of the incoming HTTP request. Accepts the name of a parameter, and its contents. If a parameter by that name already exists, this method will replace its contents.

##### Example

```javascript
var requestObject = tester.createMockRequest();

requestObject.addParam('query', { myField: 'myValue' });

client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### setAuthenticatedUsername(username)

Set the username of the authenticated Kinvey user making the simulated request. This is the username accessible to your business logic code by the `modules.backendContext.getAuthenticatedUsername()` method (for more details, please check our [business logic reference](http://devcenter.kinvey.com/reference/business-logic/reference.html#backendcontext-module)).

##### Example

```javascript
var requestObject = tester.createMockRequest();

requestObject.setAuthenticatedUsername('myUsername');

client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### setTempObjectStore(jsonObject)

Set the value of the temporary object store available to your business logic code through `modules.utils.tempObjectStore`. For more details, please check our [business logic reference](http://devcenter.kinvey.com/rest/reference/business-logic/reference.html#utils-module).

##### Example

```javascript
var requestObject = tester.createMockRequest();

var objectStore = {
  myProperty: 'myValue'
};

requestObject.setTempObjectStore(objectStore);

client.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### toJSON()

Returns the JSON object representing the request built by this helper.

##### Example

```javascript
var tester = require('business-logic-testing-library');

var requestObject = tester.createMockRequest({ body: { testing: true }});

requestObject.setAuthenticatedUsername('myUser');

console.log(requestObject.toJSON());

/* outputs:
{
  body: {
    testing: true
  },
  username: 'myUser'
}
*/
```

### Mock response builder

In order to run business logic using any of the *run...* methods listed on this page, you must pass in a response object. This object contains data and metadata about the (simulated) outgoing HTTP response (FROM Kinvey TO the client). In order to simplify the use of this object, you can use the `mock-response-builder` helper module, which exposes an API to create a response object.

#### Usage and constructor

To use the response builder, require the testing module, and then call its createMockResponse method. The constructor optionally accepts a JSON object containing initial values.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var options = { ... };

var responseObject = tester.createMockResponse({ body: { testing: true }});

tester.createClient(options, function(err, client) {
  if (err) {
    // handle error
  }

  client.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
});
```

#### Chaining

With the exception of `toJSON`, all methods of the response builder return the instance of the builder, allowing for chained method calls. For example:

```javascript
var tester = require('business-logic-testing-library');
var responseObject = tester.createMockResponse();
responseObject.setBody({ testing: true }).setStatusCode(200);
```

#### setBody(jsonObject)

Set the `body` property of the response object, which corresponds to the body of the outgoing HTTP response. Accepts a JSON object.

##### Example

```javascript
var responseObject = tester.createMockResponse();

responseObject.setBody({ testing: true });

client.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### setHeaders(jsonObject)

Set the `headers` property of the response object, which corresponds to the headers of the outgoing HTTP response. Accepts a JSON object in which keys are header names and values are header contents.

##### Example

```javascript
var responseObject = tester.createMockResponse();

responseObject.setHeaders({ 'x-kinvey-api-version': 3 });

client.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### addHeader(name, contents)

Add a header to the `headers` property of the response object, which corresponds to the headers of the outgoing HTTP response. Accepts the name of a header, and its contents. If a header by that name already exists, this method will replace its contents.

##### Example

```javascript
var responseObject = tester.createMockResponse();

responseObject.addHeader('x-kinvey-api-version', 3);

client.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### setStatusCode(code)

Set the status code of the response object, which corresponds to the HTTP status code of the outgoing HTTP response.

##### Example

```javascript
var responseObject = tester.createMockResponse();

responseObject.setStatusCode(200);

client.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### toJSON()

Returns the JSON object representing the response built by this helper.

##### Example

```javascript
var tester = require('business-logic-testing-library');

var responseObject = tester.createMockResponse({ body: { testing: true }});

responseObject.setStatusCode(200);

console.log(responseObject.toJSON());

/* outputs:
{
  body: {
    testing: true
  },
  status: 200
}
*/
```

## Utilities

### Setup

Start the required Docker images and return a tester instance. Prior to running this method, make sure Docker is installed properly. The set-up method expects a [`jsonConfiguration` object](createclientjsonconfiguration-callback) as first parameter. The set-up method is best used in a before-hook of your test suite.

##### Example
```
// Assuming Mocha.
var tester = require('business-logic-testing-library');

var options = {
  blRootPath: '/Users/JohnDoe/Documents/kinvey/business-logic',
  environmentID: 'MyAwesomeEnvironment'
}

before(function(done) {
  tester.util.setup(options, function(err, client) {
    if(err) {
      // handle error
    }

    // client...
  });
});
```

### Teardown

Currently, the teardown method is an empty method. This might change in the future.

##### Example
```
// Assuming Mocha.
var tester = require('business-logic-testing-library');

var options = {
  blRootPath: '/Users/JohnDoe/Documents/kinvey/business-logic',
  environmentID: 'MyAwesomeEnvironment'
}

before(...);

after(function(done) {
  tester.util.teardown(options, done);
});
```

## License
    Copyright 2015 Kinvey, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.