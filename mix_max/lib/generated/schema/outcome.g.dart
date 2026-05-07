// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaOutcome _$SchemaOutcomeFromJson(Map<String, dynamic> json) =>
    SchemaOutcome(
      id: json['id'] as String,
      name: json['name'] as String?,
      unit: json['unit'] as String?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      goal: $enumDecodeNullable(_$OutcomeGoalEnumMap, json['goal']),
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
  writeNotNull('unit', instance.unit);
  writeNotNull('min', instance.min);
  writeNotNull('max', instance.max);
  writeNotNull('goal', _$OutcomeGoalEnumMap[instance.goal]);
  return val;
}

const _$OutcomeGoalEnumMap = {
  OutcomeGoal.minimize: 'minimize',
  OutcomeGoal.maximize: 'maximize',
};
