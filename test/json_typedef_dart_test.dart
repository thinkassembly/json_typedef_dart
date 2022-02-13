import 'package:flutter_test/flutter_test.dart';

import 'package:json_typedef_dart/json_typedef_dart.dart';
import 'package:json_typedef_dart/src/types.dart';

import 'invalid_schemas.dart';

void main() {

   for(var testCase in InvalidSchemas.entries) {
    test(testCase.key,(){
      expect(isValidSchema(testCase.value as Json ),false);
    });
   }

}
