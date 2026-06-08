import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/services/firebase/database_service.dart';
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

  /// Number of runs completed for this experiment, kept on the experiment so
  /// the run total can be shown without loading the Runs collection. Bumped by
  /// [recordCompletedRun] each time a run is logged.
  int runCount;

  /// Seconds since Unix epoch.
  int? createdAt;

  /// Seconds since Unix epoch of the last time this experiment's parameter set
  /// changed in a way that invalidates earlier runs (a parameter added, edited
  /// or deleted). Runs generated before this moment used a different parameter
  /// set, so the optimizer ignores them when suggesting the next run. Null when
  /// the parameters have never been edited.
  int? lastParametersUpdatedAt;

  SchemaExperiment({
    required this.id,
    this.userId,
    this.name,
    this.parameters,
    this.outcomes,
    this.bestRun,
    this.runCount = 0,
    this.createdAt,
    this.lastParametersUpdatedAt,
  });

  SchemaExperiment.unknown({
    this.id = "",
    this.userId,
    this.name,
    this.parameters,
    this.outcomes,
    this.bestRun,
    this.runCount = 0,
    this.createdAt,
    this.lastParametersUpdatedAt,
  });

  bool isValid() {
    return id.isNotEmpty;
  }

  /// Stamps [lastParametersUpdatedAt] with the current time. Call whenever the
  /// parameter set changes (add / edit / delete) so runs recorded against the
  /// previous set stop tuning the next suggested run.
  void markParametersUpdated() {
    lastParametersUpdatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// Records a freshly completed [run]: increments [runCount], promotes it to
  /// [bestRun] when it scores higher, and persists the experiment so the count
  /// and best mix can be shown without loading the whole Runs collection.
  Future<void> recordCompletedRun(SchemaRun run) {
    runCount += 1;
    updateBestRun(run);
    return save();
  }

  /// Persists this experiment to its Firestore document, merging with the
  /// existing fields so partial updates stay safe.
  Future<void> save() {
    return DatabaseService.experimentsRef
        .doc(id)
        .set(this, SetOptions(merge: true));
  }

  /// Permanently removes this experiment's Firestore document. The cached
  /// parameters, outcomes and best run live on the document, so deleting it
  /// drops everything in one write.
  Future<void> delete() {
    return DatabaseService.experimentsRef.doc(id).delete();
  }

  /// Promotes [run] to [bestRun] when it scores higher than the run already
  /// stored (or when none is stored yet), duplicating it onto this experiment.
  ///
  /// Each run is scored with [SchemaRun.finalRating] against its own outcome
  /// snapshot (higher is better), so the comparison honours the outcomes each
  /// run was actually measured with. Returns true when [bestRun] changed — the
  /// signal for the caller to persist the experiment.
  bool updateBestRun(SchemaRun run) {
    final current = bestRun;

    if (current != null && run.finalRating() <= current.finalRating()) {
      return false;
    }

    bestRun = run;
    return true;
  }

  factory SchemaExperiment.fromJson(Map<String, dynamic> json) => _$SchemaExperimentFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaExperimentToJson(this);
}
