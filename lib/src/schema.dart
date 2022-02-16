import 'package:collection/collection.dart';
import 'package:json_typedef_dart/src/types.dart';

const FormsMap validForms = {
  // Empty form

  SchemaType.emptyForm: [
    {
      [false, false, false, false, false, false, false, false, false, false]: validateDefinitions
    }
  ],
  // Ref form

  SchemaType.refForm: [
    {
      [true, false, false, false, false, false, false, false, false, false]: isValidRefForm
    }
  ],
  // Type form

  SchemaType.typeForm: [
    {
      [false, true, false, false, false, false, false, false, false, false]: isValidTypeForm
    }
  ],
  // Enum form

  SchemaType.enumForm: [
    {
      [false, false, true, false, false, false, false, false, false, false]: isValidEnumForm
    }
  ],
  // Elements form

  SchemaType.elementsForm: [
    {
      [false, false, false, true, false, false, false, false, false, false]: isValidElementsForm
    }
  ],
  // Properties form -- properties or optional properties or both, and never
  // additional properties on its own

  SchemaType.propertiesForm: [
    {
      [false, false, false, false, true, false, false, false, false, false]: isValidPropertiesForm
    },
    {
      [false, false, false, false, false, true, false, false, false, false]: isValidPropertiesForm
    },
    {
      [false, false, false, false, true, true, false, false, false, false]: isValidPropertiesForm
    },
    {
      [false, false, false, false, true, false, true, false, false, false]: isValidPropertiesForm
    },
    {
      [false, false, false, false, false, true, true, false, false, false]: isValidPropertiesForm
    },
    {
      [false, false, false, false, true, true, true, false, false, false]: isValidPropertiesForm
    },
  ],
  // Values form

  SchemaType.valuesForm: [
    {
      [false, false, false, false, false, false, false, true, false, false]: isValidValuesForm
    }
  ],
  // Discriminator form

  SchemaType.discriminatorForm: [
    {
      [false, false, false, false, false, false, false, false, true, true]: isValidDiscriminatorForm
    }
  ]
};
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

bool hasRef(Json schema) => schema.containsKey("ref");

bool isValidRefForm(Json schema, Json root) {
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

bool hasElements(Json schema) => schema.containsKey("elements");

bool hasEnum(Json schema) => schema.containsKey("enum");

bool hasProperties(Json schema) => schema.containsKey("properties");

bool hasValues(Json schema) => schema.containsKey("values");

bool hasDefinitions(Json schema) => schema.containsKey('definitions');
bool hasNullable(Json schema) => schema.containsKey("nullable");

bool hasDiscriminator(Json schema) => schema.containsKey("discriminator");
bool hasMapping(Json schema) => schema.containsKey("mapping");
bool hasOptionalProperties(Json schema) => schema.containsKey("optionalProperties");

bool hasAdditionalProperties(Json schema) => schema.containsKey("additionalProperties");

bool isValidTypeForm(Json schema, Json root) => (schema["type"] is String) && (validTypes.contains(schema["type"]));

bool isValidEnumForm(Json schema, Json root) {
  if ((schema["enum"] is! List)) {
    return false;
  }
  if ((schema["enum"] as List).isEmpty) {
    return false;
  }
  if ((schema["enum"] as List).length != Set<dynamic>.from(schema["enum"] as List).length) {
    return false;
  }
  for (var enum_ in schema["enum"]) {
    if (enum_ is! String) {
      return false;
    }
  }
  return true;
}

bool isValidElementsForm(Json schema, Json root) {
  if (schema["elements"] is! Json) {
    return false;
  }
  if (!isValidSchema(schema["elements"] as Json, root)) {
    return false;
  }
  return true;
}

bool isProperties(Json schema) => schema.containsKey("properties") || schema.containsKey("optionalProperties");

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
        if ((Map<String, dynamic>.from(schema["optionalProperties"] as Json)).containsKey(key)) {
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

bool validateProperties(Json schema, Json root) => isProperties(schema) ? isValidProperties(schema, root) : true;

bool isValidValuesForm(Json schema, Json root) {
  if (schema["values"] is! Json) {
    return false;
  }
  if (isValidSchema(schema["values"] as Json, root) == false) {
    return false;
  }
  return true;
}


bool isValidDiscriminatorForm(Json schema, Json root) {
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

    if (subSchema["properties"] is Json && (subSchema["properties"] as Json).containsKey(schema["discriminator"])) {
      return false;
    }
    if (hasOptionalProperties(subSchema)) {
      if ((subSchema["optionalProperties"] as Json).containsKey(schema["discriminator"])) {
        return false;
      }
    }
  }
  return true;
}

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

bool validateDefinitions(Json schema, Json root) => hasDefinitions(schema) ? isValidDefinitions(schema, root) : true;

bool isValidAdditionalProperties(Json schema) => schema["additionalProperties"] is bool;

bool validateAdditionalProperties(Json schema) => hasAdditionalProperties(schema) ? isValidAdditionalProperties(schema) : true;


bool isValidPropertiesForm(Json schema, Json root) {
  if (!validateDefinitions(schema, root)) {
    return false;
  }
  if (!validateProperties(schema, root)) {
    return false;
  }
  if (!validateAdditionalProperties(schema)) {
    return false;
  }
  return true;
}

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

bool isValidSchemaForm(Json schema, Json root) {
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

  for (var validForm in validForms.entries) {
    for (var formSignatures in validForm.value) {
      for (var form in formSignatures.entries) {
        if (const ListEquality<bool>().equals(form.key, formSignature) == true) {
          return form.value(schema, root);
        }
      }
    }
  }
  return false;
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
  if (!isValidSchemaForm(schema, root)) {
    return false;
  }

  return true;
}
