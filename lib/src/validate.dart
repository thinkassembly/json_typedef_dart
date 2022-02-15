import 'package:json_typedef_dart/src/errors.dart';
import 'package:json_typedef_dart/src/rfc339.dart';
import 'package:json_typedef_dart/src/schema.dart';
import 'package:json_typedef_dart/src/types.dart';

class ValidationError {
  List<String> instancePath;
  List<String> schemaPath;

  ValidationError({required this.instancePath, required this.schemaPath});

  Json toMap() {
    return <String, dynamic>{
      "instancePath": instancePath,
      "schemaPath": schemaPath
    };
  }
}

class ValidationState {
  List<ValidationError> errors = [];
  List<String> instanceTokens = [];
  List<List<String>> schemaTokens = [[]];
  Json root;

  int maxDepth;
  int maxErrors;

  ValidationState({required this.root, this.maxDepth = 0, this.maxErrors = 0});

  List<Map<String, dynamic>> errorList() {
    List<Map<String, dynamic>> err = [];

    for (ValidationError error in errors) {
      err.add( error.toMap());
    }
    return err;
  }
  void popSchemaToken() {
    schemaTokens.last.removeLast();
  }
  void pushSchemaToken( String token) {
    schemaTokens.last.add(token);
  }

  void popInstanceToken() {
    instanceTokens.removeLast();
  }
}

ValidationErrors validate(
    {required Json schema,
    required dynamic data,
    int maxDepth = 0,
    int maxErrors = 0}) {
  ValidationState state =
      ValidationState(root: schema, maxDepth: maxDepth, maxErrors: maxErrors);
  try {
    validateWithState(state: state, schema: schema, instance: data);
  } catch (e) {
    if (e is MaxErrorsReachedError) {
    } else {
      rethrow;
    }
    return state.errorList();
  }
  return state.errorList();
}

void validateWithState(
    {required ValidationState state,
    required Json schema,
    required dynamic instance,
    String? parentTag}) {
  if (hasNullable(schema) && instance == null) {
    return;
  }
  if (hasRef(schema)) {
    if (state.schemaTokens.length == state.maxDepth) {
      throw MaxDepthExceededError();
    }
    state.schemaTokens.add(["definitions", schema["ref"] as String]);
    validateWithState(
        state: state,
        schema: state.root["definitions"]![schema["ref"]] as Json,
        instance: instance);
    state.schemaTokens.removeLast();
  } else if (hasType(schema)) {
    state.pushSchemaToken( "type");
    switch (schema["type"]) {
      case 'boolean':
        if (instance is! bool) {
          pushError(state);
        }
        break;
      case "float32":
      case "float64":
        if (instance is! num) {
          pushError(state);
        }
        break;
      case "int8":
        validateInt(state, instance, -128, 127);
        break;
      case "uint8":
        validateInt(state, instance, 0, 255);
        break;
      case "int16":
        validateInt(state, instance, -32768, 32767);
        break;
      case "uint16":
        validateInt(state, instance, 0, 65535);
        break;
      case "int32":
        validateInt(state, instance, -2147483648, 2147483647);
        break;
      case "uint32":
        validateInt(state, instance, 0, 4294967295);
        break;
      case "string":
        if (instance is! String) {
          pushError(state);
        }
        break;
      case "timestamp":
        if (instance is! String) {
          pushError(state);
        } else {

         if (!isRFC3339(instance)) {
            pushError(state);
          }
        }
        break;
    }
    state.popSchemaToken();
  } else if (hasEnum(schema)) {
    state.pushSchemaToken( "enum");

    var enum_ = List<String>.from(schema["enum"] as List<dynamic>);
    if (instance is! String ||
        !(enum_.contains(instance ))) {
      pushError(state);
    }
    state.popSchemaToken();
  } else if (hasElements(schema)) {
    state.pushSchemaToken( "elements");

    if (instance is List) {
      for (var i = 0;i< instance.length ;i++) {
        pushInstanceToken(state, i.toString());
        validateWithState(
            state: state,
            schema: schema["elements"] as Json,
            instance: instance[i]);
        state.popInstanceToken();
      }
    } else {
      pushError(state);
    }

    state.popSchemaToken();
  } else if (isProperties(schema)) {
    // JSON has six basic types of data (null, boolean, number, string,
    // array, object). Of their standard JS countparts, three have a
    // `typeof` of "object": null, array, and object.
    //
    // This check attempts to check if something is "really" an object.
    if (instance is Json) {
      if (hasProperties(schema)) {
        state.pushSchemaToken( "properties");
        for (var subSchema in (schema["properties"] as Json).entries) {
          state.pushSchemaToken( subSchema.key);
          if (instance.containsKey(subSchema.key)) {
            pushInstanceToken(state, subSchema.key);
            validateWithState(
                state: state,
                schema: subSchema.value as Json,
                instance: instance[subSchema.key]);
            state.popInstanceToken();
          } else {
            pushError(state);
          }
          state.popSchemaToken();;
        }
        state.popSchemaToken();;
      }

      if (hasOptionalProperties(schema)) {
        state.pushSchemaToken( "optionalProperties");
        for (var subSchema in (schema["optionalProperties"] as Json).entries) {
          state.pushSchemaToken( subSchema.key);
          if (instance.containsKey(subSchema.key)) {
            pushInstanceToken(state, subSchema.key);
            validateWithState(
                state: state,
                schema: subSchema.value as Json,
                instance: instance[subSchema.key]);
            state.popInstanceToken();
          }
          state.popSchemaToken();;
        }
        state.popSchemaToken();;
      }

      if (!hasAdditionalProperties(schema) || schema["additionalProperties"] != true) {
        for (var name in instance.keys) {
          bool inRequired = hasProperties(schema) &&
              (schema["properties"] as Json).containsKey(name);
          bool inOptional = hasOptionalProperties(schema) &&
              (schema["optionalProperties"] as Json).containsKey(name);

          if (!inRequired && !inOptional && name != parentTag) {
            pushInstanceToken(state, name);
            pushError(state);
            state.popInstanceToken();
          }
        }
      }
    } else {
      if (hasProperties(schema)) {
        state.pushSchemaToken( "properties");
      } else {
        state.pushSchemaToken( "optionalProperties");
      }

      pushError(state);
      state.popSchemaToken();;
    }
  } else if (hasValues(schema)) {
    state.pushSchemaToken( "values");

    // See comment in properties form on why this is the test we use for
    // checking for objects.
    if (instance is Json) {
      for (var subInstance in instance.entries) {
        pushInstanceToken(state, subInstance.key);
        validateWithState(
            state: state,
            schema: schema["values"] as Json,
            instance: subInstance.value);
        state.popInstanceToken();
      }
    } else {
      pushError(state);
    }

    state.popSchemaToken();;
  } else if (hasDiscriminator(schema)) {
    // See comment in properties form on why this is the test we use for
    // checking for objects.
    if (instance is Json) {
      if (instance.containsKey(schema["discriminator"])) {
        if(instance[schema["discriminator"]] is String) {
          String tag = instance[schema["discriminator"]] as String;

          if ((schema["mapping"] as Json).containsKey(tag)) {
            state.pushSchemaToken( "mapping");
            state.pushSchemaToken( tag);
            validateWithState(
                state: state,
                schema: schema["mapping"][tag] as Json,
                instance: instance,
                parentTag: schema["discriminator"] as String);
            state.popSchemaToken();
            state.popSchemaToken();
          } else {
            state.pushSchemaToken( "mapping");
            pushInstanceToken(state, schema["discriminator"] as String);
            pushError(state);
            state.popInstanceToken();
            state.popSchemaToken();
          }
        }
        else {
          state.pushSchemaToken( "discriminator");
          pushInstanceToken(state, schema["discriminator"].toString());
          pushError(state);
          state.popInstanceToken();
          state.popSchemaToken();;

        }

      } else {
        state.pushSchemaToken( "discriminator");
        pushError(state);
        state.popSchemaToken();
      }
    } else {
      state.pushSchemaToken( "discriminator");
      pushError(state);
      state.popSchemaToken();
    }
  }
}

void pushInstanceToken(ValidationState state, String token) {
  state.instanceTokens.add(token);
}







void pushError(ValidationState state) {
  state.errors.add(

      ValidationError(
        instancePath: [...state.instanceTokens],
        schemaPath: [...state.schemaTokens[state.schemaTokens.length - 1]],
      ));

  if (state.errors.length == state.maxErrors) {
    throw MaxErrorsReachedError();
  }
}

void validateInt(ValidationState state, dynamic instance, num min, num max) {
  if (instance is! num ||
      instance is! int ||
      instance < min ||
      instance > max) {
    pushError(state);
  }
}
