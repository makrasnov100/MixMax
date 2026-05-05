import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/parameter.g.dart';

enum ParameterType { number, duration, toggle, choice, order }

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaParameter {
  String id;
  String? name;
  ParameterType? type;

  // number
  String? unit;
  double? min;
  double? max;

  // choice
  List<String>? options;

  // order
  List<String>? items;

  SchemaParameter({
    required this.id,
    this.name,
    this.type,
    this.unit,
    this.min,
    this.max,
    this.options,
    this.items,
  });

  SchemaParameter.unknown({
    this.id = '',
    this.name,
    this.type,
    this.unit,
    this.min,
    this.max,
    this.options,
    this.items,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaParameter.fromJson(Map<String, dynamic> json) => _$SchemaParameterFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaParameterToJson(this);
}
