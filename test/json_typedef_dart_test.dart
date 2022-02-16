import 'package:flutter_test/flutter_test.dart';

import 'package:json_typedef_dart/json_typedef_dart.dart';
import 'package:json_typedef_dart/src/errors.dart';
import 'package:json_typedef_dart/src/rfc339.dart';
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
    test("supports limited depth", () {
      Json schema = <String, dynamic>{
        "definitions": {
          "foo": {"ref": "foo"}
        },
        "ref": "foo"
      };
      Json? instance;

      expect(() => validate(schema: schema, data: instance, maxDepth: 5, maxErrors: 0), throwsA(isA<MaxDepthExceededError>()));
    });

    test("supports limited errors", () {
      Json schema = <String, dynamic>{
        "elements": {"type": "string"}
      };
      const instance = [null, null, null, null, null];

      expect(validate(schema: schema, data: instance, maxDepth: 0, maxErrors: 3).length, 3);
    });

    for (var testCase in TestSchemas.entries) {
      test(testCase.key, () {
        expect(isValidSchema(testCase.value["schema"] as Json), true);
        expect(validate(schema: testCase.value["schema"] as Json, data: testCase.value["instance"]), testCase.value["errors"]);
      });
    }
  });

  group("isRFC3339 Tests", () {
    const testCases = {
      // From the RFC
      "1985-04-12T23:20:50.52Z": true,
      "1990-12-31T23:59:60Z": true,
      "1990-12-31T15:59:60-08:00": true,
      "1937-01-01T12:00:27.87+00:20": true,

      // T and Z can be t or z
      "1985-04-12t23:20:50.52z": true,

      // From http://henry.precheur.org/python/rfc3339
      "2008-04-02T20:00:00Z": true,
      "1970-01-01T00:00:00Z": true,

      // https://github.com/chronotope/chrono/blob/main/src/format/parse.rs
      "2015-01-20T17:35:20-08:00": true, // normal case
      "1944-06-06T04:04:00Z": true, // D-day
      "2001-09-11T09:45:00-08:00": true,
      "2015-01-20T17:35:20.001-08:00": true,
      "2015-01-20T17:35:20.000031-08:00": true,
      "2015-01-20T17:35:20.000000004-08:00": true,
      "2015-01-20T17:35:20.000000000452-08:00": true, // too small
      "2015-02-30T17:35:20-08:00": false, // bad day of month
      "2015-01-20T25:35:20-08:00": false, // bad hour
      "2015-01-20T17:65:20-08:00": false, // bad minute
      "2015-01-20T17:35:90-08:00": false, // bad second

      // Ensure the regex is anchored
      "x1985-04-12T23:20:50.52Zx": false,
      "1985-04-12T23:20:50.52Zx": false,
    };
    for (var testCase in testCases.entries) {
      test(testCase.key, () {
        expect(isRFC3339(testCase.key), testCase.value);
      });
    }
  });
}
