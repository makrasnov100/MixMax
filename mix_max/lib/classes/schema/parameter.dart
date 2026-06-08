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

  // toggle — custom names for the on / off states. Null means use the
  // [defaultOnLabel] / [defaultOffLabel] fallbacks.
  String? onLabel;
  String? offLabel;

  SchemaParameter({
    required this.id,
    this.name,
    this.type,
    this.unit,
    this.min,
    this.max,
    this.options,
    this.items,
    this.onLabel,
    this.offLabel,
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
    this.onLabel,
    this.offLabel,
  });

  /// Fallbacks shown when no custom toggle label is set.
  static const String defaultOnLabel = 'On';
  static const String defaultOffLabel = 'Off';

  /// The label to show for the on state — the custom one if set, else 'On'.
  String get resolvedOnLabel =>
      onLabel?.trim().isNotEmpty == true ? onLabel!.trim() : defaultOnLabel;

  /// The label to show for the off state — the custom one if set, else 'Off'.
  String get resolvedOffLabel =>
      offLabel?.trim().isNotEmpty == true ? offLabel!.trim() : defaultOffLabel;

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaParameter.fromJson(Map<String, dynamic> json) => _$SchemaParameterFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaParameterToJson(this);
}
