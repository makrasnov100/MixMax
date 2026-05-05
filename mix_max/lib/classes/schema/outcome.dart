import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/outcome.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaOutcome {
  String id;
  String? name;

  SchemaOutcome({
    required this.id,
    this.name,
  });

  SchemaOutcome.unknown({
    this.id = '',
    this.name,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  factory SchemaOutcome.fromJson(Map<String, dynamic> json) => _$SchemaOutcomeFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaOutcomeToJson(this);
}
