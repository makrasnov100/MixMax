// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaRun _$SchemaRunFromJson(Map<String, dynamic> json) => SchemaRun(
      id: json['id'] as String,
      experimentId: json['experimentId'] as String?,
      userId: json['userId'] as String?,
      parameterValues: json['parameterValues'] as Map<String, dynamic>?,
      outcomeValues: (json['outcomeValues'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      createdAt: (json['createdAt'] as num?)?.toInt(),
      completedAt: (json['completedAt'] as num?)?.toInt(),
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
  writeNotNull('userId', instance.userId);
  writeNotNull('parameterValues', instance.parameterValues);
  writeNotNull('outcomeValues', instance.outcomeValues);
  writeNotNull('createdAt', instance.createdAt);
  writeNotNull('completedAt', instance.completedAt);
  return val;
}
