// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/parameter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaParameter _$SchemaParameterFromJson(Map<String, dynamic> json) =>
    SchemaParameter(
      id: json['id'] as String,
      name: json['name'] as String?,
      type: $enumDecodeNullable(_$ParameterTypeEnumMap, json['type']),
      unit: json['unit'] as String?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      increment: (json['increment'] as num?)?.toDouble(),
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      items:
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList(),
      onLabel: json['onLabel'] as String?,
      offLabel: json['offLabel'] as String?,
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
  writeNotNull('type', _$ParameterTypeEnumMap[instance.type]);
  writeNotNull('unit', instance.unit);
  writeNotNull('min', instance.min);
  writeNotNull('max', instance.max);
  writeNotNull('increment', instance.increment);
  writeNotNull('options', instance.options);
  writeNotNull('items', instance.items);
  writeNotNull('onLabel', instance.onLabel);
  writeNotNull('offLabel', instance.offLabel);
  return val;
}

const _$ParameterTypeEnumMap = {
  ParameterType.number: 'number',
  ParameterType.duration: 'duration',
  ParameterType.temperature: 'temperature',
  ParameterType.toggle: 'toggle',
  ParameterType.choice: 'choice',
  ParameterType.order: 'order',
};
