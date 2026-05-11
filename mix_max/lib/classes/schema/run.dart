import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/run.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaRun {
  String id;
  String? experimentId;

  /// Parameter values keyed by parameterId.
  /// Values are typed per ParameterType:
  ///   number / duration → double
  ///   toggle            → bool
  ///   choice            → String
  ///   order             → List<String>
  Map<String, dynamic>? parameterValues;

  /// Outcome values keyed by outcomeId.
  Map<String, double>? outcomeValues;

  SchemaRun({
    required this.id,
    this.experimentId,
    this.parameterValues,
    this.outcomeValues,
  });

  SchemaRun.unknown({
    this.id = '',
    this.experimentId,
    this.parameterValues,
    this.outcomeValues,
  });

  bool isValid() => id.isNotEmpty;

  factory SchemaRun.fromJson(Map<String, dynamic> json) => _$SchemaRunFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaRunToJson(this);
}
