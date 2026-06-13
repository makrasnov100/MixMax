import 'package:json_annotation/json_annotation.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
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

  /// Point-in-time snapshot of the experiment's parameter definitions as they
  /// were when this run was generated. Kept on the run so its details and
  /// history render correctly even after the experiment's parameters are later
  /// edited or deleted.
  List<SchemaParameter>? parameters;

  /// Point-in-time snapshot of the experiment's outcome definitions as they
  /// were when this run was generated. Used to score the run ([finalRating])
  /// and label its recorded values, independent of the experiment's current
  /// outcomes.
  List<SchemaOutcome>? outcomes;

  /// Seconds since Unix epoch when the run was generated.
  int? createdAt;

  /// Seconds since Unix epoch when all outcomes were recorded.
  int? completedAt;

  /// The run's combined 0–1 rating ([computeFinalRating]) frozen onto the
  /// document when it is recorded or rescored. Persisting it lets the highest
  /// scoring run be found with a single indexed query (e.g. to re-crown the
  /// best run after a delete) instead of loading and re-scoring every run.
  /// Null for legacy runs written before this field existed.
  double? finalRating;

  SchemaRun({
    required this.id,
    this.experimentId,
    this.userId,
    this.parameterValues,
    this.outcomeValues,
    this.parameters,
    this.outcomes,
    this.createdAt,
    this.completedAt,
    this.finalRating,
  });

  SchemaRun.unknown({
    this.id = '',
    this.experimentId,
    this.userId,
    this.parameterValues,
    this.outcomeValues,
    this.parameters,
    this.outcomes,
    this.createdAt,
    this.completedAt,
    this.finalRating,
  });

  bool isValid() => id.isNotEmpty;

  /// Combines this run's recorded outcomes into a single scalar rating where
  /// higher is always better.
  ///
  /// Scored against the run's own [outcomes] snapshot — the outcome definitions
  /// captured when the run was generated — so the rating reflects what was
  /// actually measured, even if the experiment's outcomes were later edited or
  /// removed. Pass [outcomesOverride] to score against a different set (e.g. a
  /// legacy run that has no stored snapshot).
  ///
  /// Each outcome is normalised to [0, 1] using its declared `min`/`max` bounds
  /// and then flipped when its goal is to minimise. Outcomes without usable
  /// bounds fall back to their raw value. The contributing outcomes are then
  /// combined as a weighted average using each outcome's [SchemaOutcome.weight]
  /// (the Priorities section's 0–100 budget). When every measured outcome is
  /// unweighted — all weights null or zero — they fall back to an equal average,
  /// so a run still scores sensibly before any priorities are set. Returns 0.0
  /// when none have a recorded value.
  ///
  /// This recomputes live from the run's values; the persisted [finalRating]
  /// field is a frozen copy of this result, written when the run is recorded or
  /// rescored so it can be queried/indexed without loading every run.
  double computeFinalRating([List<SchemaOutcome>? outcomesOverride]) {
    final ranked = outcomesOverride ?? outcomes ?? const [];
    final values = outcomeValues;
    if (values == null) return 0.0;

    // If every measured outcome has a zero/absent weight, weight them equally so
    // the rating doesn't collapse to 0 before any priorities have been set.
    final weightSum = ranked
        .where((o) => values[o.id] != null)
        .fold<double>(0.0, (a, o) => a + (o.weight ?? 0.0));
    final useEqualWeights = weightSum <= 0;

    double total = 0.0;
    double denom = 0.0;

    for (final outcome in ranked) {
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

      final weight = useEqualWeights ? 1.0 : (outcome.weight ?? 0.0);
      total += normalised * weight;
      denom += weight;
    }

    return denom > 0 ? total / denom : 0.0;
  }

  factory SchemaRun.fromJson(Map<String, dynamic> json) => _$SchemaRunFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaRunToJson(this);
}
