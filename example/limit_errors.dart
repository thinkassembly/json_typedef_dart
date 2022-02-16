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
// Outputs:
//
// [ { instancePath: [], schemaPath: [ 'properties', 'name' ] } ]
  print(validate(
      schema: schema,
      data: {
        "age": "43",
        "phones": ["+44 1234567", "+44 2345678"],
      },
      maxErrors: 1));
}
