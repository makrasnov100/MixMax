import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/outcome.g.dart';

enum OutcomeGoal { minimize, maximize }

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaOutcome {
  String id;
  String? name;
  String? unit;
  double? min;
  double? max;

  /// Increment used by the rating slider. Defaults to 1.0 when null.
  double? step;
  OutcomeGoal? goal;

  SchemaOutcome({
    required this.id,
    this.name,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.goal,
  });

  SchemaOutcome.unknown({
    this.id = '',
    this.name,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.goal,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaOutcome.fromJson(Map<String, dynamic> json) => _$SchemaOutcomeFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaOutcomeToJson(this);
}
