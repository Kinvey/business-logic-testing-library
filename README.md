# Helper module for testing Kinvey Business Logic

This module provides an easy way to connect to a Kinvey Business Logic (BL) instance running on docker. It is up to the user to download, configure and start the docker image itself before running code using this module.

The module serves two purposes:

1. Integrate with the Kinvey BL CLI tool to support offline testing of BL code.
2. Allow a developer to run a custom BL function in order to test its validity and behavior.

In order to use the module, you will first need to configure it, and then call one of its API methods. These steps are explained in more detail below.

## Table of contents

* [Configuration](#configuration)
* [Methods](#usage)
  * [configure](#configurejsonConfiguration)
  * [runCollectionHook](#runcollectionhookcollectionname-blfunctionname-requestobject-responseobject-callback)
  * [runCustomEndpoint](#runcustomendpointendpointname-requestobject-responseobject-callback)
  * [runFunction](#runfunctioncodetorun-requestobject-responseobject-callback)
  * [createRequestObject](#createrequestobjectfromjson)
  * [createResponseObject](#createresponseobjectfromjson)
* [Common code](#common-code)
* [Helpers](#helpers)
  * [Request builder](#request-builder)
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
  * [Response builder](#response-builder)
    * [Usage and constructor](#usage-and-constructor-1)
    * [Chaining](#chaining-1)
    * [setBody](#setbodyjsonobject-1)
    * [setHeaders](#setheadersjsonobject-1)
    * [addHeader](#addheadername-contents-1)
    * [setStatusCode](#setstatuscodecode)
    * [toJSON](#tojson-1)

## Configuration

The tester module exposes a `configure` method, which accepts a JSON object. This is a synchronous method that simply sets a few internal variables. The structure of the JSON object supports the following properties:

| property name | type | description | default value |
| ------------- | ---- | ----------- | ------------- |
| containerHostOrIP | string | the hostname or IP address of the docker container running the BL instance | 'localhost' |
| containerPort | number | the port of the docker container running the BL instance | 8080 |
| blRootPath | string | the path to the root of the `business-logic` folder created by using the BL CLI tool | N/A |
| environmentID | string | the ID of the environment to simulate | 'BusinessLogicTest' |
| appSecret | string | the app secret of the simulated environment | '_environmentID_-app-secret' |
| masterSecret | string | the master secret of the simulated environment | '_environmentID_-master-secret' |

*Note* that you do not need to specify all values. Generally, you will want to configure the testing module with the `containerHostOrIP`, `containerPort`, and `blRootPath` parameters. As for the other, environment-specific configuration parameters, these are provided as an option in case your BL code relies on this information.

### Example

```javascript
var tester = require('business-logic-testing-library');

var options = {
  containerHostOrIP: '192.168.59.103',
  containerPort: 2375,
  blRootPath: '/Users/foobar/Documents/kinvey/business-logic',
  environmentID: 'MyAwesomeEnvironment'
}

tester.configure(options);
```

## Usage

The module exposes the following API:

#### configure(jsonConfiguration)

Configure the module. Described in detail [above](#Configuration).


#### runCollectionHook(collectionName, blFunctionName, requestObject, responseObject, callback)

Run the code contained within a collection hook. This method relies on the existence of the collection hook .js file within the BL CLI folder structure. For example, if your collection is called `MyCollection`, and you are running an post-fetch hook, the tester will look for the code at `_blRootPath_/collections/MyCollection/onPostFetch.js`.

##### Arguments

| name | type | description |
| ---- | ---- | ----------- |
| collectionName | string | the name of the collection associated with the hook |
| blFunctionName | string | the hook function to call. One of: `onPreSave`, `onPostSave`, `onPreFetch`, `onPostFetch`, `onPreDelete`, `onPostDelete` |
| requestObject | JSON or request-builder instance | the object made available to the BL code through the `request` variable |
| responseObject | JSON or response-builder instance | the object made available to the BL code through the `response` variable |
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

tester.runCollectionHook('MyCollection', 'onPreSave', requestObject, responseObject, function(error, blResult) {
  if (error) {
    // handle the error
  }
  else {
    console.log("Received response with body:", blResult.response.body);
  }
});
```


#### runCustomEndpoint(endpointName, requestObject, responseObject, callback)

Run the code contained within a custom endpoint. This method relies on the existence of the endpoint .js file within the BL CLI folder structure. For example, if your endpoint is called `myEndpoint`, the tester will look for the code at `_blRootPath_/endpoints/myEndpoint.js`.

##### Arguments

| name | type | description |
| ---- | ---- | ----------- |
| endpointName | string | the name of the endpoint you wish to run |
| requestObject | JSON or request-builder instance | the object made available to the BL code through the `request` variable |
| responseObject | JSON or response-builder instance | the object made available to the BL code through the `response` variable |
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

tester.runCustomEndpoint('myEndpoint', requestObject, responseObject, function(error, blResult) {
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
| requestObject | JSON or request-builder instance | the object made available to the BL code through the `request` variable |
| responseObject | JSON or response-builder instance | the object made available to the BL code through the `response` variable |
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

var helloWorld = function onRequest(request, resopnse, modules) {
  response.body = { 'hello': 'world' };
  response.complete();
};

tester.runFunction(helloWorld, requestObject, responseObject, function(error, blResult) {
  if (error) {
    // handle the error
  }
  else {
    console.log("Received response with body:", blResult.response.body);
  }
});
```

#### createRequestObject(fromJSON)

Create an instance of the request builder, which can be used to construct a request object to pass to the *run* functioned described above. For more details, take a look at the [request builder documentation](#request-builder) below.

#### createResponseObject(fromJSON)

Create an instance of the response builder, which can be used to construct a response object to pass to the *run* functioned described above. For more details, take a look at the [response builder documentation](#response-builder) below.

## Common code

All methods support common code defined within the BL CLI folder structure. When any of the `run...` methods described above are called, the tester will read the contents of all common code files contained within the `_blRootPath_/common/` directory (if any exist), which will be executed before running your collection hook/custom endpoint/function code.

##### Example



```javascript
/**** contents of _blRootPath/common/helperFunctions.js ***/
var timesTwo = function(number) {
  return (number * 2);
}
/**** end of helperFunctions.js ****/


/**** contents of _blRootPath/custom/myEndpoint.js ***/
function onRequest(request, resopnse, modules) {
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

tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {
  if (error) {
    console.log("Error encountered! details:", error);
  }
  else {
    console.log("4 * 2 is", blResult.response.body.multipliedNumber);
  }
});
```

## Helpers

### Request builder

In order to run business logic using any of the *run* methods listed on this page, you must pass in a request object. This object contains data and metadata about the (simulated) incoming HTTP request (FROM the client TO Kinvey), and is used to pass necessary information to the testing framework. In order to simplify the use of this object, you can use the `request-builder` helper module, which exposes an API to create a request object.

#### Usage and constructor

To use the request builder, require the testing module, and then call its createRequestObject method. The constructor optionally accepts a JSON object containing initial values.

##### Example

```javascript
var tester = require('business-logic-testing-library');

var requestObject = tester.createRequetObject({ body: { testing: true }});
tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### Chaining

With the exception of `toJSON`, all methods of the request builder return the instance of the builder, allowing for chained method calls. For example:

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createRequetObject();
requestObject.setBody({ testing: true }).addHeader('x-kinvey-api-version', 3);
```

#### setBody(jsonObject)

Set the `body` property of the request object, which corresponds to the body of the incoming HTTP request. Accepts a JSON object.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createRequetObject();

requestObject.setBody({ testing: true });

tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### setHeaders(jsonObject)

Set the `headers` property of the request object, which corresponds to the headers of the incoming HTTP request. Accepts a JSON object in which keys are header names and values are header contents.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createRequetObject();

requestObject.setHeaders({ 'x-kinvey-api-version': 3 });

tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### addHeader(name, contents)

Add a header to the `headers` property of the request object, which corresponds to the headers of the incoming HTTP request. Accepts the name of a header, and its contents. If a header by that name already exists, this method will replace its contents.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createRequetObject();

requestObject.addHeader('x-kinvey-api-version', 3);

tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### setParams(jsonObject)

Set the `params` property of the request object, which corresponds to the parameters of the incoming HTTP request. Accepts a JSON object in which keys are parameter names and values are their contents.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createRequetObject();

requestObject.setParams({ 'query': { myField: 'myValue' }});

tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### addParam(name, contents)

Add a parameter to the `params` property of the request object, which corresponds to the parameters of the incoming HTTP request. Accepts the name of a parameter, and its contents. If a parameter by that name already exists, this method will replace its contents.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createRequetObject();

requestObject.addParam('query', { myField: 'myValue' });

tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### setAuthenticatedUsername(username)

Set the username of the authenticated Kinvey user making the simulated request. This is the username accessible to your business logic code by the `modules.backendContext.getAuthenticatedUsername()` method (for more details, please check our [business logic reference](http://devcenter.kinvey.com/reference/business-logic/reference.html#backendcontext-module)).

##### Example

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createRequetObject();

requestObject.setAuthenticatedUsername('myUsername');

tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### setTempObjectStore(jsonObject)

Set the value of the temporary object store available to your business logic code through `modules.utils.tempObjectStore`. For more details, please cehck our [business logic reference](http://devcenter.kinvey.com/rest/reference/business-logic/reference.html#utils-module).

##### Example

```javascript
var tester = require('business-logic-testing-library');
var requestObject = tester.createRequetObject();

var objectStore = {
  myProperty: 'myValue'
};

requestObject.setTempObjectStore(objectStore);

tester.runCustomEndpoint('myEndpoint', requestObject, {}, function(error, blResult) {});
```

#### toJSON()

Returns the JSON object representing the request built by this helper.

##### Example

```javascript
var tester = require('business-logic-testing-library');

var requestObject = tester.createRequetObject({ body: { testing: true }});

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

### Response builder

In order to run business logic using any of the *run* methods listed on this page, you must pass in a response object. This object contains data and metadata about the (simulated) outgoing HTTP response (FROM Kinvey TO the client). In order to simplify the use of this object, you can use the `response-builder` helper module, which exposes an API to create a response object.

#### Usage and constructor

To use the response builder, require the testing module, and then call its createResponseObject method. The constructor optionally accepts a JSON object containing initial values.

##### Example

```javascript
var tester = require('business-logic-testing-library');

var responseObject = tester.createResponseObject({ body: { testing: true }});
tester.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### Chaining

With the exception of `toJSON`, all methods of the response builder return the instance of the builder, allowing for chained method calls. For example:

```javascript
var tester = require('business-logic-testing-library');
var responseObject = tester.createResponseObject();
responseObject.setBody({ testing: true }).setStatusCode(200);
```

#### setBody(jsonObject)

Set the `body` property of the response object, which corresponds to the body of the outgoing HTTP response. Accepts a JSON object.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var responseObject = tester.createResponseObject();

responseObject.setBody({ testing: true });

tester.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### setHeaders(jsonObject)

Set the `headers` property of the response object, which corresponds to the headers of the outgoing HTTP response. Accepts a JSON object in which keys are header names and values are header contents.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var responseObject = tester.createResponseObject();

responseObject.setHeaders({ 'x-kinvey-api-version': 3 });

tester.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### addHeader(name, contents)

Add a header to the `headers` property of the response object, which corresponds to the headers of the outgoing HTTP response. Accepts the name of a header, and its contents. If a header by that name already exists, this method will replace its contents.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var responseObject = tester.createResponseObject();

responseObject.addHeader('x-kinvey-api-version', 3);

tester.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### setStatusCode(code)

Set the status code of the response object, which corresponds to the HTTP status code of the outgoing HTTP response.

##### Example

```javascript
var tester = require('business-logic-testing-library');
var responseObject = tester.createResponseObject();

responseObject.setStatusCode(200);

tester.runCustomEndpoint('myEndpoint', {}, responseObject, function(error, blResult) {});
```

#### toJSON()

Returns the JSON object representing the response built by this helper.

##### Example

```javascript
var tester = require('business-logic-testing-library');

var responseObject = tester.createResponseObject({ body: { testing: true }});

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
