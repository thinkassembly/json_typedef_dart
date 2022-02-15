import 'package:flutter_test/flutter_test.dart';

import 'package:json_typedef_dart/json_typedef_dart.dart';
import 'package:json_typedef_dart/src/types.dart';

import 'invalid_schemas.dart';
import 'schema_validation.dart';

void main() {
  group("Schema Validation", () {
    for (var testCase in InvalidSchemas.entries) {
      test(testCase.key, () {
        expect(isValidSchema(testCase.value as Json), false);
      });
    }
  });

  group("JSON Validation", () {
    for (var testCase in TestSchemas.entries) {
      test(testCase.key, () {
        print(testCase.value["schema"]);
        print(testCase.value["instance"]);
        print(testCase.value["errors"]);
        expect(
            validate(
                schema: testCase.value["schema"] as Json,
                data: testCase.value["instance"]),
            testCase.value["errors"]);
      });
    }
  });
}
