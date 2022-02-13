import 'package:json_typedef_dart/src/types.dart';

class Schema {
  late Json schema;

  Schema(this.schema) {
    isValid();
  }

  bool isValid() {
    return false;
  }
}

bool isRef(Json schema) => schema.containsKey("ref");

bool isEmpty(Json schema) => schema.isEmpty;

bool isType(Json schema) => schema.containsKey("type");

bool isEnum(Json schema) => schema.containsKey("enum");

bool isElements(Json schema) => schema.containsKey("elements");

bool isProperties(Json schema) =>
    schema.containsKey("properties") ||
    schema.containsKey("optionalProperties");

bool isValues(Json schema) => schema.containsKey("values");

bool isDiscriminator(Json schema) => schema.containsKey("discriminator");

bool hasDefinitions(Json schema) => schema.containsKey('definitions');

bool hasNullable(Json schema) => schema.containsKey("nullable");

bool isValidSchema(Json? schema, [Json? root]) {
  if (schema == null) return false;
  root = root ?? schema;

  for (var key in schema.keys) {
    if (![
      "properties",
      "definitions",
      "enum",
      "optionalProperties",
      "values",
      "discriminator",
      "nullable"
    ].contains(key)) {
      return false;
    }
  }
  if (hasNullable(schema)) {
    if (schema["nullable"] is! bool) {
      return false;
    }
  }
  if (hasDefinitions(schema)) {
    if (root != schema) {
      return false;
    }
    if (schema["definitions"] is! Json) {
      return false;
    }
    for (var subSchema in schema['definitions'].values) {
      if(subSchema is! Json) {
        return false;
      }
      if (!isValidSchema(subSchema, root)) {
        return false;
      }
    }
  }

  // Make sure ref is in root definitions.
  if (isRef(schema)) {
    if (root["definitions"] == null) {
      return false;
    }
    if (root["definitions"] is! Json) {
      return false;
    }
    if (!((root["definitions"] as Json).containsKey(schema["ref"]))) {
      return false;
    }
  }

  if (isEnum(schema)) {
    if ((schema["enum"] is! List<String>)) {
      return false;
    }
    if ((schema["enum"] as List).isEmpty) {
      return false;
    }
    if ((schema["enum"] as List).length !=
        Set<dynamic>.from(schema["enum"] as List).length) {
      return false;
    }
  }
  if (isElements(schema)) {
    if(schema["elements"] is! Json) {
      return false;
    }
    return isValidSchema(schema["elements"] as Json, root);
  }

  if (isProperties(schema)) {
    if (schema['properties'] is! Json) {
      return false;
    }
    for (var subSchema in schema["properties"].values) {
      if(subSchema is! Json) {
        return false;
      }
      if (!isValidSchema(Map<String, dynamic>.from(subSchema as Json), root)) {
        return false;
      }
    }
    for (Json subSchema in schema["optionalProperties"].values) {
      if (!isValidSchema(subSchema, root)) {
        return false;
      }
    }

    for (var key in schema["properties"].keys) {
      print(key);
      if ((Map<String, dynamic>.from(schema["optionalProperties"] as Json))
          .containsKey(key)) {
        return false;
      }
    }
  }

  if (isValues(schema)) {
    if (schema["values"] is! Json) {
      return false;
    }
    return isValidSchema(schema["values"] as Json, root);
  }

  if (isDiscriminator(schema)) {
    if(schema["mapping"] is! Json) {
      return false;
    }
    for (var subSchema in schema["mapping"].values) {
      if (!isValidSchema(subSchema as Json, root) || !isProperties(subSchema)) {
        return false;
      }

      if (subSchema["nullable"] == true) {
        return false;
      }

      if ((subSchema["properties"] as Json)
          .containsKey(schema["discriminator"])) {
        return false;
      }
      if ((subSchema["optionalProperties"] as Json)
          .containsKey(schema["discriminator"])) {
        return false;
      }
    }
  }

  return true;
}
