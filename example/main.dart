// ignore_for_file: avoid_print

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
