import 'package:json_annotation/json_annotation.dart';
part '../../generated/schema/user.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaUser {
  String id;
  String? name;
  String? email;

  SchemaUser({
    required this.id,
    this.name,
    this.email,
  });

  SchemaUser.unknown({
    this.id = "",
    this.name,
    this.email,
  });

  SchemaUser.initial({
    this.id = "INITIAL",
    this.name,
    this.email,
  });

  isValid() {
    return id.isNotEmpty && id != "INITIAL";
  }

  factory SchemaUser.fromJson(Map<String, dynamic> json) => _$SchemaUserFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaUserToJson(this);
}
