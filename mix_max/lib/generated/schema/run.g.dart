// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaRun _$SchemaRunFromJson(Map<String, dynamic> json) => SchemaRun(
      id: json['id'] as String,
      experimentId: json['experimentId'] as String?,
      parameterValues: json['parameterValues'] != null
          ? Map<String, dynamic>.from(json['parameterValues'] as Map)
          : null,
      outcomeValues: (json['outcomeValues'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$SchemaRunToJson(SchemaRun instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('experimentId', instance.experimentId);
  writeNotNull('parameterValues', instance.parameterValues);
  writeNotNull('outcomeValues', instance.outcomeValues);
  return val;
}
