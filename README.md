# jtd: JSON Validation for Dart


[JSON Type Definition](https://jsontypedef.com), aka [RFC
8927](https://tools.ietf.org/html/rfc8927), is an easy-to-learn, standardized
way to define a schema for JSON data. You can use JSON Typedef to portably
validate data across programming languages, create dummy data, generate code,
and more.

This package is a Dart / Flutter implementation of JSON Type
Definition. It lets you validate input data against JSON Type Definition
schemas. 



## Installation

You can install this package with `pub`:

```bash

```

## Documentation



For more high-level documentation about JSON Typedef in general see:

* [The JSON Typedef Website][jtd]

## Basic Usage

Here's an example of how you can use this package to validate JSON data against
a JSON Typedef schema:

```dart
import 'package:json_typedef_dart/json_typedef_dart.dart';

Json schema = <String, dynamic>{
   "properties": {
      "name": {"type": "string"},
      "age": {"type": "uint32"},
      "phones": {
         "elements": {"type": "string"}
      }
   }
};

void main() {
// validate returns an array of validation errors. If there were no problems
// with the input, it returns an empty array.

// Outputs: []
   print(validate(schema: schema, data: {
      "name": "John Doe",
              "age": 43,
              "phones": ["+44 1234567", "+44 2345678"],
   }));

// This next input has three problems with it:
//
// 1. It's missing "name", which is a required property.
// 2. "age" is a string, but it should be an integer.
// 3. "phones[1]" is a number, but it should be a string.
//
// Each of those errors corresponds to one of the errors returned by validate.

// Outputs:
//
// [
//   { instancePath: [], schemaPath: [ 'properties', 'name' ] },
//   {
//     instancePath: [ 'age' ],
//     schemaPath: [ 'properties', 'age', 'type' ]
//   },
//   {
//     instancePath: [ 'phones', '1' ],
//     schemaPath: [ 'properties', 'phones', 'elements', 'type' ]
//   }
// ]
   print(validate(schema: schema, data: {
      "age": "43",
              "phones": ["+44 1234567", 442345678],
   }));
}
```

## Advanced Usage: Limiting Errors Returned

By default, `validate` returns every error it finds. If you just care about
whether there are any errors at all, or if you can't show more than some number
of errors, then you can get better performance out of `validate` using the
`maxErrors` option.

For example, taking the same example from before, but limiting it to 1 error, we
get:

```dart
import 'package:json_typedef_dart/json_typedef_dart.dart';

Json schema = <String, dynamic>{
   "properties": {
      "name": {"type": "string"},
      "age": {"type": "uint32"},
      "phones": {
         "elements": {"type": "string"}
      }
   }
};

void main() {
// Outputs:
//
// [ { instancePath: [], schemaPath: [ 'properties', 'name' ] } ]
   print(validate(schema: schema, data: {
      "age": "43",
              "phones": ["+44 1234567", "+44 2345678"],
   },maxErrors: 1));

}
```

## Advanced Usage: Handling Untrusted Schemas

If you want to run `validate` against a schema that you don't trust, then you should:

1. Ensure the schema is well-formed, using  `isValidSchema` which validates things like making sure all `ref`s have
   corresponding definitions.

2. Call `validate` with the `maxDepth` option. JSON Typedef lets you write
   recursive schemas -- if you're evaluating against untrusted schemas, you
   might go into an infinite loop when evaluating against a malicious input,
   such as this one:

   ```json
   {
     "ref": "loop",
     "definitions": {
       "loop": {
         "ref": "loop"
       }
     }
   }
   ```

   The `maxDepth` option tells `jtd.validate` how many `ref`s to follow
   recursively before giving up and throwing `MaxDepthExceededError`.

Here's an example of how you can use `jtd` to evaluate data against an untrusted
schema:

```dart
import 'package:json_typedef_dart/json_typedef_dart.dart';

// validateUntrusted returns true if `data` satisfies `schema`, and false if it
// does not. Throws an error if `schema` is invalid, or if validation goes in an
// infinite loop.
bool validateUntrusted(Json schema, dynamic data) {
   if (!isValidSchema(schema)) {
      throw Exception("invalid schema");
   }

// You should tune maxDepth to be high enough that most legitimate schemas
// evaluate without errors, but low enough that an attacker cannot cause a
// denial of service attack.
   return validate(schema: schema, data: data, maxDepth: 32).isEmpty;
}

void main() {
// Outputs: true
   print(validateUntrusted(<String, dynamic>{"type": "string"}, "foo"));

// Outputs: false
   validateUntrusted(<String, dynamic>{"type": "string"}, null);

// Throws "invalid schema"
   try {
      validateUntrusted(<String, dynamic>{"type": "nonsense"}, null);
   } catch (e) {
      print(e);
   }
// Throws an instance of MaxDepthExceededError
   try {
      validateUntrusted(<String, dynamic>{
         "ref": "loop",
         "definitions": {
            "loop": {"ref": "loop"}
         }
      }, null);
   }
   catch(e){
      print(e);
   }
}
```


