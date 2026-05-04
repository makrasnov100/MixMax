import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/experiment.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaExperiment {
  String id;
  String? name;

  SchemaExperiment({
    required this.id,
    this.name,
  });

  SchemaExperiment.unknown({
    this.id = "",
    this.name,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaExperiment.fromJson(Map<String, dynamic> json) => _$SchemaExperimentFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaExperimentToJson(this);
}
