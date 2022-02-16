typedef Json = Map<String, dynamic>;
typedef ValidationErrors = List<Map<String, dynamic>>;
typedef FormsMap = Map<SchemaType,
    List<Map<List<bool>, bool Function(Json schema, Json root)>>>;
enum ValueType {
  boolean,
  float32,
  float64,
  int8,
  uint8,
  int16,
  uint16,
  int32,
  uint32,
  string,
  timestamp
}

enum SchemaType {
  emptyForm,
  typeForm,
  enumForm,
  elementsForm,
  propertiesForm,
  valuesForm,
  discriminatorForm,
  refForm,
  invalidForm
}
