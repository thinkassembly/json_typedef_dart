import 'package:collection/collection.dart';
import 'package:json_typedef_dart/src/types.dart';

const VALID_FORMS = [
  // Empty form
  [false, false, false, false, false, false, false, false, false, false],
  // Ref form
  [true, false, false, false, false, false, false, false, false, false],
  // Type form
  [false, true, false, false, false, false, false, false, false, false],
  // Enum form
  [false, false, true, false, false, false, false, false, false, false],
  // Elements form
  [false, false, false, true, false, false, false, false, false, false],
  // Properties form -- properties or optional properties or both, and never
  // additional properties on its own
  [false, false, false, false, true, false, false, false, false, false],
  [false, false, false, false, false, true, false, false, false, false],
  [false, false, false, false, true, true, false, false, false, false],
  [false, false, false, false, true, false, true, false, false, false],
  [false, false, false, false, false, true, true, false, false, false],
  [false, false, false, false, true, true, true, false, false, false],
  // Values form
  [false, false, false, false, false, false, false, true, false, false],
  // Discriminator form
  [false, false, false, false, false, false, false, false, true, true],
];
const VALID_TYPES = [
  "boolean",
  "float32",
  "float64",
  "int8",
  "uint8",
  "int16",
  "uint16",
  "int32",
  "uint32",
  "string",
  "timestamp",
];

class Schema {
  late Json schema;

  Schema(this.schema) {
    isValid();
  }

  bool isValid() {
    return false;
  }
}

bool hasRef(Json schema) => schema.containsKey("ref");

bool isValidRef(Json schema, Json root) {

  if (root["definitions"] is! Json) {
    return false;
  }
  if (!((root["definitions"] as Json).containsKey(schema["ref"]))) {
    return false;
  }
  return true;
}

bool isEmpty(Json schema) => schema.isEmpty;

bool hasType(Json schema) => schema.containsKey("type");

bool isValidType(Json schema) =>
    (schema["type"] is String) && (VALID_TYPES.contains(schema["type"]));

bool hasEnum(Json schema) => schema.containsKey("enum");

bool isValidEnum(Json schema) {

  if ((schema["enum"] is! List)) {

    return false;
  }
  if ((schema["enum"] as List).isEmpty) {
    return false;
  }
  if ((schema["enum"] as List).length !=
      Set<dynamic>.from(schema["enum"] as List).length) {
    return false;
  }
  for(var enum_ in schema["enum"]) {
    if(enum_ is! String){
      return false;
    }

  }
  return true;
}

bool hasElements(Json schema) => schema.containsKey("elements");

bool isValidElements(Json schema, Json root) {


  if (schema["elements"] is! Json) {
    return false;
  }
  if (!isValidSchema(schema["elements"] as Json, root)) {
    return false;
  }
  return true;
}

bool isProperties(Json schema) =>
    schema.containsKey("properties") ||
    schema.containsKey("optionalProperties");

bool hasProperties(Json schema) => schema.containsKey("properties");

bool hasValues(Json schema) => schema.containsKey("values");

bool isValidValues(Json schema, Json root) {
  if (schema["values"] is! Json) {
    return false;
  }
  if (isValidSchema(schema["values"] as Json, root) == false) {
    return false;
  }
  return true;
}

bool isDiscriminator(Json schema) => schema.containsKey("discriminator");

bool hasDiscriminator(Json schema) => schema.containsKey("discriminator");

bool hasDefinitions(Json schema) => schema.containsKey('definitions');

bool hasNullable(Json schema) => schema.containsKey("nullable");

bool hasOptionalProperties(Json schema) =>
    schema.containsKey("optionalProperties");

bool hasAdditionalProperties(Json schema) =>
    schema.containsKey("additionalProperties");

bool isValidAdditionalProperties(Json schema) =>
    schema["additionalProperties"] is bool;

bool hasMapping(Json schema) => schema.containsKey("mapping");

bool hasValidKeys(Json schema) {
  for (var key in schema.keys) {
    if (![
      "properties",
      "definitions",
      "enum",
      "optionalProperties",
      "values",
      "discriminator",
      "nullable",
      "type",
      "mapping",
      "ref",
      "additionalProperties",
      "metadata",
      "elements"
    ].contains(key)) {
      return false;
    }
  }
  return true;
}

bool hasValidForm(Json schema) {
  var formSignature = [
    hasRef(schema),
    hasType(schema),
    hasEnum(schema),
    hasElements(schema),
    hasProperties(schema),
    hasOptionalProperties(schema),
    hasAdditionalProperties(schema),
    hasValues(schema),
    hasDiscriminator(schema),
    hasMapping(schema),
  ];
  Function eq = const ListEquality<bool>().equals;

  bool formOK = false;

  for (var validForm in VALID_FORMS) {
    if (eq(validForm, formSignature) == true) {
      formOK = true;
      break;
    }
  }
  return formOK;
}

bool isValidSchema(Json? schema, [Json? root]) {
  if (schema == null) return false;
  root = root ?? schema;

  if (!hasValidKeys(schema)) {
    return false;
  }
  if (hasNullable(schema)) {
    if (schema["nullable"] is! bool) {
      return false;
    }
  }

  if (hasType(schema) && !isValidType(schema)) {
    return false;
  }
  if (hasEnum(schema) && !isValidEnum(schema)) {
    return false;
  }

  if (hasAdditionalProperties(schema) && !isValidAdditionalProperties(schema)) {
    return false;
  }

  if (hasElements(schema) && !isValidElements(schema, root)) {
    return false;
  }

  // Make sure ref is in root definitions.
  if (hasRef(schema) && !isValidRef(schema, root)) {
    return false;
  }

  if (hasValues(schema) && !isValidValues(schema, root)) {
    return false;
  }

  if (hasDefinitions(schema)) {
    if (root != schema) {
      return false;
    }
    if (schema["definitions"] is! Json) {
      return false;
    }
    for (var subSchema in schema['definitions'].values) {
      if (subSchema is! Json) {
        return false;
      }
      if (!isValidSchema(subSchema, root)) {

        return false;
      }
    }
  }

  if (isProperties(schema)) {
    if (schema['properties'] is! Json && schema["optionalProperties"] is! Json) {
      return false;
    }
    if (schema['properties'] is Json) {
      for (var subSchema in schema["properties"].values) {
        if (subSchema is! Json) {
          return false;
        }
        if (!isValidSchema(Map<String, dynamic>.from(subSchema), root)) {
          return false;
        }
      }
    }
    if (hasOptionalProperties(schema)) {
      for (Json subSchema in schema["optionalProperties"].values) {
        if (!isValidSchema(subSchema, root)) {
          return false;
        }
      }
    }
    if (schema['properties'] is Json) {
      for (var key in schema["properties"].keys) {
        if (schema["optionalProperties"] is Json) {
          if ((Map<String, dynamic>.from(schema["optionalProperties"] as Json))
              .containsKey(key)) {
            return false;
          }
        }
      }
    }
  }

  if (isDiscriminator(schema)) {
    if (schema["discriminator"] is! String) {
      return false;
    }
    if (schema["mapping"] is! Json) {
      return false;
    }

    for (var subSchema in schema["mapping"].values) {
      if (subSchema["nullable"] == true) {
        return false;
      }

      if (!isValidSchema(subSchema as Json, root) || !isProperties(subSchema)) {
        return false;
      }

      if (subSchema["properties"] != null && (subSchema["properties"] as Json)
          .containsKey(schema["discriminator"])) {
        return false;
      }
      if(hasOptionalProperties(subSchema)) {
        if ((subSchema["optionalProperties"] as Json)
            .containsKey(schema["discriminator"])) {
          return false;
        }
      }
    }
  }

  if (!hasValidForm(schema)) {
    return false;
  }
  return true;
}
