// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaOutcome _$SchemaOutcomeFromJson(Map<String, dynamic> json) =>
    SchemaOutcome(
      id: json['id'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$SchemaOutcomeToJson(SchemaOutcome instance) {
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
