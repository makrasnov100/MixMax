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

  // number / duration — optional granularity. Mix Max only ever suggests values
  // that land on the grid (min + k×increment), so a whole-number increment makes
  // the parameter integers-only. Null means smooth (any value within range).
  double? increment;

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
    this.increment,
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
    this.increment,
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

  /// Snaps [value] to the increment grid (min + k×increment) when a positive
  /// [increment] is set, clamped to [min] / [max]; returns [value] unchanged
  /// otherwise. Mirrors `screens.jsx` `suggestValue`.
  double snapToIncrement(double value) {
    final step = increment;
    if (step == null || step <= 0) return value;
    final lo = min ?? 0.0;
    final snapped = lo + ((value - lo) / step).round() * step;
    var result = double.parse(snapped.toStringAsFixed(6));
    if (result < lo) result = lo;
    if (max != null && result > max!) result = max!;
    return result;
  }

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaParameter.fromJson(Map<String, dynamic> json) => _$SchemaParameterFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaParameterToJson(this);
}
