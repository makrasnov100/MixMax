import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/parameter.g.dart';

enum ParameterType { number, duration, toggle, choice, order }

/// The time units a [ParameterType.duration] value can be expressed in. The
/// parameter's [SchemaParameter.unit] holds one of these [label]s and its
/// values are plain numbers in that unit (e.g. unit `minutes`, value `1.5` →
/// 90 seconds). [inSeconds] is how many real seconds one of the unit is, used
/// to convert to the `1h 30m` display form; [short] is that form's suffix.
enum DurationUnit {
  seconds(1, 'seconds', 's'),
  minutes(60, 'minutes', 'm'),
  hours(3600, 'hours', 'h');

  const DurationUnit(this.inSeconds, this.label, this.short);

  final int inSeconds;
  final String label;
  final String short;

  /// The unit matching a stored [label], defaulting to [minutes] when the
  /// label is missing or unrecognised (e.g. a legacy free-typed unit).
  static DurationUnit fromLabel(String? label) => values.firstWhere(
        (u) => u.label == label,
        orElse: () => DurationUnit.minutes,
      );
}

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

  /// The time unit a [ParameterType.duration] parameter's values are stored in,
  /// derived from [unit] and defaulting to minutes. Only meaningful for the
  /// duration type.
  DurationUnit get durationUnit => DurationUnit.fromLabel(unit);

  /// Renders [value] — a number in this parameter's [durationUnit] — as a
  /// compact `1h 30m 5s` string, dropping any zero components and rounding to
  /// whole seconds (no decimal places). A value that rounds to nothing shows as
  /// `0` in the parameter's own unit (e.g. `0m`); null / NaN render as `—`.
  ///
  /// This is the single place duration values are formatted for display — see
  /// the suggested-run, run-history, share, and details previews that call it.
  String formatDuration(num? value) {
    if (value == null || (value is double && value.isNaN)) return '—';
    final unit = durationUnit;
    var total = (value * unit.inSeconds).round();
    final negative = total < 0;
    total = total.abs();

    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final parts = <String>[
      if (h > 0) '${h}h',
      if (m > 0) '${m}m',
      if (s > 0) '${s}s',
    ];
    if (parts.isEmpty) parts.add('0${unit.short}');
    return '${negative ? '-' : ''}${parts.join(' ')}';
  }

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

  factory SchemaParameter.fromJson(Map<String, dynamic> json) =>
      _$SchemaParameterFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaParameterToJson(this);
}
