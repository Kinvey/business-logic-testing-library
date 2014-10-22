# Helper module for testing Kinvey Business Logic

This module provides an easy way to connect to a Kinvey Business Logic (BL) instance running on docker. It is up to the user to download, configure and start the docker image itself before running code using this module.

The module serves two purposes:

1. Integrate with the Kinvey BL CLI tool to support offline testing of BL code.
2. Allow a developer to run a custom BL function in order to test its validity and behavior.

In order to use the module, you will first need to configure it, and then call one of its API methods. These steps are explained in more detail below.

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
| requestObject | JSON | the object made available to the BL code through the `request` variable |
| responseObject | JSON | the object made available to the BL code through the `response` variable |
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
| requestObject | JSON | the object made available to the BL code through the `request` variable |
| responseObject | JSON | the object made available to the BL code through the `response` variable |
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


#### runCollectionHook(collectionName, blFunctionName, requestObject, responseObject, callback)

Run the code contained within a collection hook. This method relies on the existence of the collection hook .js file within the BL CLI folder structure. For example, if your collection is called `MyCollection`, and you are running an post-fetch hook, the tester will look for the code at `_blRootPath_/collections/MyCollection/onPostFetch.js`.

##### Arguments

| name | type | description |
| ---- | ---- | ----------- |
| collectionName | string | the name of the collection associated with the hook |
| blFunctionName | string | the hook function to call. One of: `onPreSave`, `onPostSave`, `onPreFetch`, `onPostFetch`, `onPreDelete`, `onPostDelete` |
| requestObject | JSON | the object made available to the BL code through the `request` variable |
| responseObject | JSON | the object made available to the BL code through the `response` variable |
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


#### runFunction(codeToRun, requestObject, responseObject, callback)

Run code from a function or a function string. The function must match the custom endpoint signature: `function onRequest(request, response, modules){ ... }`.

##### Arguments

| name | type | description |
| ---- | ---- | ----------- |
| codeToRun | function or string | code you wish to run |
| requestObject | JSON | the object made available to the BL code through the `request` variable |
| responseObject | JSON | the object made available to the BL code through the `response` variable |
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
