// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/experiment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaExperiment _$SchemaExperimentFromJson(Map<String, dynamic> json) =>
    SchemaExperiment(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String?,
      parameters: (json['parameters'] as List<dynamic>?)
          ?.map((e) => SchemaParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      outcomes: (json['outcomes'] as List<dynamic>?)
          ?.map((e) => SchemaOutcome.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestRun: json['bestRun'] == null
          ? null
          : SchemaRun.fromJson(json['bestRun'] as Map<String, dynamic>),
      runCount: (json['runCount'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as num?)?.toInt(),
      lastParametersUpdatedAt:
          (json['lastParametersUpdatedAt'] as num?)?.toInt(),
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

  writeNotNull('userId', instance.userId);
  writeNotNull('name', instance.name);
  writeNotNull(
      'parameters', instance.parameters?.map((e) => e.toJson()).toList());
  writeNotNull('outcomes', instance.outcomes?.map((e) => e.toJson()).toList());
  writeNotNull('bestRun', instance.bestRun?.toJson());
  val['runCount'] = instance.runCount;
  writeNotNull('createdAt', instance.createdAt);
  writeNotNull('lastParametersUpdatedAt', instance.lastParametersUpdatedAt);
  return val;
}
