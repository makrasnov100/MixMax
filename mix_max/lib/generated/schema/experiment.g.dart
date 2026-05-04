// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/experiment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaExperiment _$SchemaExperimentFromJson(Map<String, dynamic> json) =>
    SchemaExperiment(
      id: json['id'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$SchemaExperimentToJson(SchemaExperiment instance) {
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
