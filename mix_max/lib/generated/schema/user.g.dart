// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../classes/schema/user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaUser _$SchemaUserFromJson(Map<String, dynamic> json) => SchemaUser(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$SchemaUserToJson(SchemaUser instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('email', instance.email);
  return val;
}
