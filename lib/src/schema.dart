import 'package:collection/collection.dart';
import 'package:json_typedef_dart/src/types.dart';

List<Map<SchemaType, List<List<bool>>>> validForms = [
  // Empty form
  {
    SchemaType.emptyForm: [
      [false, false, false, false, false, false, false, false, false, false]
    ]
  },
  // Ref form
  {
    SchemaType.refForm: [
      [true, false, false, false, false, false, false, false, false, false]
    ]
  },
  // Type form
  {
    SchemaType.typeForm: [
      [false, true, false, false, false, false, false, false, false, false]
    ]
  },
  // Enum form
  {
    SchemaType.enumForm: [
      [false, false, true, false, false, false, false, false, false, false]
    ]
  },
  // Elements form
  {
    SchemaType.elementsForm: [
      [false, false, false, true, false, false, false, false, false, false]
    ]
  },
  // Properties form -- properties or optional properties or both, and never
  // additional properties on its own
  {
    SchemaType.propertiesForm: [
      [false, false, false, false, true, false, false, false, false, false],
      [false, false, false, false, false, true, false, false, false, false],
      [false, false, false, false, true, true, false, false, false, false],
      [false, false, false, false, true, false, true, false, false, false],
      [false, false, false, false, false, true, true, false, false, false],
      [false, false, false, false, true, true, true, false, false, false]
    ]
  },
  // Values form
  {
    SchemaType.valuesForm: [
      [false, false, false, false, false, false, false, true, false, false]
    ]
  },
  // Discriminator form
  {
    SchemaType.discriminatorForm: [
      [false, false, false, false, false, false, false, false, true, true]
    ]
  },
];
const validTypes = [
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

bool validateRef(Json schema, Json root) =>
    hasRef(schema) ? isValidRef(schema, root) : true;

bool isEmpty(Json schema) => schema.isEmpty;

bool hasType(Json schema) => schema.containsKey("type");

bool isValidType(Json schema) =>
    (schema["type"] is String) && (validTypes.contains(schema["type"]));

bool validateType(Json schema) => hasType(schema) ? isValidType(schema) : true;

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
  for (var enum_ in schema["enum"]) {
    if (enum_ is! String) {
      return false;
    }
  }
  return true;
}

bool validateEnum(Json schema) => hasEnum(schema) ? isValidEnum(schema) : true;

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

bool validateElements(Json schema, Json root) =>
    hasElements(schema) ? isValidElements(schema, root) : true;

bool isProperties(Json schema) =>
    schema.containsKey("properties") ||
    schema.containsKey("optionalProperties");

bool hasProperties(Json schema) => schema.containsKey("properties");

bool isValidProperties(Json schema, Json root) {
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
    for (var key in schema["properties"].keys) {
      if (schema["optionalProperties"] is Json) {
        if ((Map<String, dynamic>.from(schema["optionalProperties"] as Json))
            .containsKey(key)) {
          return false;
        }
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
  return true;
}

bool validateProperties(Json schema, Json root) =>
    isProperties(schema) ? isValidProperties(schema, root) : true;

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

bool validateValues(Json schema, Json root) =>
    hasValues(schema) ? isValidValues(schema, root) : true;

bool hasDiscriminator(Json schema) => schema.containsKey("discriminator");

bool isValidDiscriminator(Json schema, Json root) {
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

    if (subSchema["properties"] is Json &&
        (subSchema["properties"] as Json)
            .containsKey(schema["discriminator"])) {
      return false;
    }
    if (hasOptionalProperties(subSchema)) {
      if ((subSchema["optionalProperties"] as Json)
          .containsKey(schema["discriminator"])) {
        return false;
      }
    }
  }
  return true;
}

bool validateDiscriminator(Json schema, Json root) =>
    hasDiscriminator(schema) ? isValidDiscriminator(schema, root) : true;

bool hasDefinitions(Json schema) => schema.containsKey('definitions');

bool isValidDefinitions(Json schema, Json root) {
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

  return true;
}

bool validateDefinitions(Json schema, Json root) =>
    hasDefinitions(schema) ? isValidDefinitions(schema, root) : true;

bool hasNullable(Json schema) => schema.containsKey("nullable");

bool hasOptionalProperties(Json schema) =>
    schema.containsKey("optionalProperties");

bool hasAdditionalProperties(Json schema) =>
    schema.containsKey("additionalProperties");

bool isValidAdditionalProperties(Json schema) =>
    schema["additionalProperties"] is bool;

bool validateAdditionalProperties(Json schema) =>
    hasAdditionalProperties(schema)
        ? isValidAdditionalProperties(schema)
        : true;

bool hasMapping(Json schema) => schema.containsKey("mapping");

const validSchemaKeys = [
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
];

bool hasValidKeys(Json schema) {
  for (var key in schema.keys) {
    if (!validSchemaKeys.contains(key)) {
      return false;
    }
  }
  return true;
}

SchemaType hasValidForm(Json schema) {
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

  SchemaType formOK = SchemaType.invalidForm;

  for (var validForm in validForms) {
    for (var matches in validForm.entries) {
      for (var form in matches.value) {
        if (eq(form, formSignature) == true) {
          formOK = matches.key;
          break;
        }
      }
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
  var schemaType = hasValidForm(schema);
  if (hasNullable(schema)) {
    if (schema["nullable"] is! bool) {
      return false;
    }
  }

  switch (schemaType) {
    case SchemaType.typeForm:
      return validateType(schema);
    case SchemaType.enumForm:
      return validateEnum(schema);
    case SchemaType.elementsForm:
      return validateElements(schema, root);
    case SchemaType.refForm:
      return validateRef(schema, root);
    case SchemaType.valuesForm:
      return validateValues(schema, root);
    case SchemaType.discriminatorForm:
      return validateDiscriminator(schema, root);
    case SchemaType.propertiesForm:
      if (!validateDefinitions(schema, root)) {
        return false;
      }
      if (!validateProperties(schema, root)) {
        return false;
      }
      if (!validateAdditionalProperties(schema)) {
        return false;
      }
      break;
    case SchemaType.emptyForm:
      return validateDefinitions(schema, root);
    case SchemaType.invalidForm:
      return false;
  }

  return true;
}
