
import 'package:json_typedef_dart/src/schema.dart';
import 'package:json_typedef_dart/src/types.dart';

class ValidationError {
  List<String> instancePath;
  List<String> schemaPath;
  ValidationError({required this.instancePath,required this.schemaPath});
}

class ValidationState {
List<ValidationError> errors = [];
List<String> instanceTokens =[];
List<List<String>> schemaTokens = [];
Json root ;
int maxDepth;
int maxErrors;
ValidationState({required this.root,this.maxDepth = 0,this.maxErrors = 0});
}
ValidationErrors validate({required Json schema, required dynamic data,int maxDepth=0, int maxErrors=0}) {




  return [];
}


void validateWithState() {

}