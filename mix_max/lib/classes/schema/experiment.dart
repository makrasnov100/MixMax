import 'package:json_annotation/json_annotation.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/run.dart';
part '../../generated/schema/experiment.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SchemaExperiment {
  String id;
  String? userId;
  String? name;
  List<SchemaParameter>? parameters;
  List<SchemaOutcome>? outcomes;

  /// The best run recorded so far, duplicated from the Runs collection so the
  /// experiment can show its leading mix without loading every run. Updated
  /// whenever a run is completed with a higher [SchemaRun.finalRating].
  SchemaRun? bestRun;

  /// Seconds since Unix epoch.
  int? createdAt;

  SchemaExperiment({
    required this.id,
    this.userId,
    this.name,
    this.parameters,
    this.outcomes,
    this.bestRun,
    this.createdAt,
  });

  SchemaExperiment.unknown({
    this.id = "",
    this.userId,
    this.name,
    this.parameters,
    this.outcomes,
    this.bestRun,
    this.createdAt,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  /// Promotes [run] to [bestRun] when it scores higher than the run already
  /// stored (or when none is stored yet), duplicating it onto this experiment.
  ///
  /// Ratings are compared with [SchemaRun.finalRating] against this
  /// experiment's [outcomes] (higher is better). Returns true when [bestRun]
  /// changed — the signal for the caller to persist the experiment.
  bool updateBestRun(SchemaRun run) {
    final current = bestRun;
    final ranked = outcomes ?? const [];

    if (current != null &&
        run.finalRating(ranked) <= current.finalRating(ranked)) {
      return false;
    }

    bestRun = run;
    return true;
  }

  factory SchemaExperiment.fromJson(Map<String, dynamic> json) => _$SchemaExperimentFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaExperimentToJson(this);
}
