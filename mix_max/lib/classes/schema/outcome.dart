import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/outcome.g.dart';

enum OutcomeGoal { minimize, maximize }

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaOutcome {
  String id;
  String? name;

  /// Optional grading guide ("how should this be graded?") shown while rating
  /// a run so scores stay consistent across runs.
  String? description;
  String? unit;
  double? min;
  double? max;

  /// Increment used by the rating slider. Defaults to 1.0 when null.
  double? step;
  OutcomeGoal? goal;

  /// How much this outcome counts toward a run's rating, on a 0–100 budget
  /// shared across the experiment's outcomes (the Priorities section). Set via
  /// the weight sliders and normalised to sum to 100 when an experiment is run.
  /// Null is treated as 0 (no weight) and falls back to an equal split when
  /// every outcome is unweighted. Captured onto each run's outcome snapshot so
  /// a run keeps the priorities it was scored with.
  double? weight;

  SchemaOutcome({
    required this.id,
    this.name,
    this.description,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.goal,
    this.weight,
  });

  SchemaOutcome.unknown({
    this.id = '',
    this.name,
    this.description,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.goal,
    this.weight,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaOutcome.fromJson(Map<String, dynamic> json) => _$SchemaOutcomeFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaOutcomeToJson(this);
}
