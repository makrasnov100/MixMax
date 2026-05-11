import 'package:json_annotation/json_annotation.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/outcome.dart';
part '../../generated/schema/experiment.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaExperiment {
  String id;
  String? userId;
  String? name;
  List<SchemaParameter>? parameters;
  List<SchemaOutcome>? outcomes;

  /// Seconds since Unix epoch.
  int? createdAt;

  SchemaExperiment({
    required this.id,
    this.userId,
    this.name,
    this.parameters,
    this.outcomes,
    this.createdAt,
  });

  SchemaExperiment.unknown({
    this.id = "",
    this.userId,
    this.name,
    this.parameters,
    this.outcomes,
    this.createdAt,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaExperiment.fromJson(Map<String, dynamic> json) => _$SchemaExperimentFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaExperimentToJson(this);
}
