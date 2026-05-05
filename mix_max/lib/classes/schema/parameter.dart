import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/parameter.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaParameter {
  String id;
  String? name;

  SchemaParameter({
    required this.id,
    this.name,
  });

  SchemaParameter.unknown({
    this.id = '',
    this.name,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaParameter.fromJson(Map<String, dynamic> json) => _$SchemaParameterFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaParameterToJson(this);
}
