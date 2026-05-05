// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/parameter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaParameter _$SchemaParameterFromJson(Map<String, dynamic> json) =>
    SchemaParameter(
      id: json['id'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$SchemaParameterToJson(SchemaParameter instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  return val;
}
