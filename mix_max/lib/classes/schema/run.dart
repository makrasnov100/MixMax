import 'package:json_annotation/json_annotation.dart';
import 'package:mix_max/classes/schema/outcome.dart';
part '../../generated/schema/run.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaRun {
  String id;
  String? experimentId;
  String? userId;

  /// Parameter values keyed by parameterId.
  /// Values are typed per ParameterType:
  ///   number / duration → double
  ///   toggle            → bool
  ///   choice            → String
  ///   order             → List<String>
  Map<String, dynamic>? parameterValues;

  /// Outcome values keyed by outcomeId.
  Map<String, double>? outcomeValues;

  /// Seconds since Unix epoch when the run was generated.
  int? createdAt;

  /// Seconds since Unix epoch when all outcomes were recorded.
  int? completedAt;

  SchemaRun({
    required this.id,
    this.experimentId,
    this.userId,
    this.parameterValues,
    this.outcomeValues,
    this.createdAt,
    this.completedAt,
  });

  SchemaRun.unknown({
    this.id = '',
    this.experimentId,
    this.userId,
    this.parameterValues,
    this.outcomeValues,
    this.createdAt,
    this.completedAt,
  });

  bool isValid() => id.isNotEmpty;

  /// Combines this run's recorded outcomes into a single scalar rating where
  /// higher is always better.
  ///
  /// Each outcome is normalised to [0, 1] using its declared `min`/`max` bounds
  /// and then flipped when its goal is to minimise. Outcomes without usable
  /// bounds fall back to their raw value. The contributing outcomes are then
  /// averaged. Returns 0.0 when none of [outcomes] have a recorded value.
  double finalRating(List<SchemaOutcome> outcomes) {
    final values = outcomeValues;
    if (values == null) return 0.0;

    double total = 0.0;
    int count = 0;

    for (final outcome in outcomes) {
      final value = values[outcome.id];
      if (value == null) continue;

      final lo = outcome.min;
      final hi = outcome.max;

      double normalised;
      if (lo != null && hi != null && hi > lo) {
        normalised = ((value - lo) / (hi - lo)).clamp(0.0, 1.0);
      } else {
        // No usable bounds — use the raw value directly.
        normalised = value;
      }

      // Higher is better, so invert when the goal is to minimise.
      if (outcome.goal == OutcomeGoal.minimize) {
        normalised = 1.0 - normalised;
      }

      total += normalised;
      count++;
    }

    return count > 0 ? total / count : 0.0;
  }

  factory SchemaRun.fromJson(Map<String, dynamic> json) => _$SchemaRunFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaRunToJson(this);
}
