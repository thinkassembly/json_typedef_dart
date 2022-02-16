// ignore_for_file: avoid_print

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
