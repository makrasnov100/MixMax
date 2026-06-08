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

  /// Persists just [runCount] and the cached [bestRun] — the two fields the run
  /// management flows touch. When [bestRun] has been cleared (no scored runs
  /// remain) a merge-set would leave the stale value behind, since null fields
  /// are omitted from the JSON, so the field is explicitly deleted instead.
  Future<void> _persistBestRunAndCount() {
    final docRef = DatabaseService.experimentsRef.doc(id);
    final best = bestRun;
    if (best == null) {
      return docRef.update({
        'runCount': runCount,
        'bestRun': FieldValue.delete(),
      });
    }
    return docRef.update({'runCount': runCount, 'bestRun': best.toJson()});
  }

  /// Re-crowns [bestRun] by querying the single highest-rated run straight from
  /// the Runs collection (indexed on [SchemaRun.finalRating]) rather than
  /// loading and re-scoring every run. Pass [excludeRunId] to ignore a run whose
  /// delete may not yet be reflected by the query. Sets [bestRun] to null when
  /// no scored run remains. The caller persists the experiment afterwards.
  Future<void> recrownBestRunFromDb({String? excludeRunId}) async {
    final snapshot = await DatabaseService.runsRef
        .where('userId', isEqualTo: userId)
        .where('experimentId', isEqualTo: id)
        .orderBy('finalRating', descending: true)
        .limit(excludeRunId == null ? 1 : 2)
        .get();

    SchemaRun? top;
    for (final doc in snapshot.docs) {
      if (doc.id == excludeRunId) continue;
      final run = doc.data();
      if (run.isValid()) {
        top = run;
        break;
      }
    }
    bestRun = top;
  }

  /// Permanently deletes [run] from the Runs collection, then keeps this
  /// experiment's cached run count and best run in sync and persists them.
  ///
  /// When the deleted run was the cached [bestRun], the next best is found via
  /// [recrownBestRunFromDb] — a single indexed query for the highest rating —
  /// so the leading mix never silently points at a deleted run.
  Future<void> deleteRun(SchemaRun run) async {
    await DatabaseService.runsRef.doc(run.id).delete();

    if (runCount > 0) runCount -= 1;

    if (bestRun?.id == run.id) {
      await recrownBestRunFromDb(excludeRunId: run.id);
    }
    await _persistBestRunAndCount();
  }

  /// Re-evaluates the cached [bestRun] after [run] was rescored — its run
  /// document already rewritten with the new outcome values and rating — then
  /// persists the experiment.
  ///
  /// • When the rescored run *was* the cached best, its rating may have moved
  ///   up or down, so the best is re-crowned from the database to stay correct
  ///   even if it slipped behind another run.
  /// • Otherwise the rescored run is promoted when it now ties or beats the
  ///   cached best — a tie still promotes it, since equal ratings can hide
  ///   differently scored outcomes and the freshly rescored run wins the tie.
  Future<void> applyRescoredRun(SchemaRun run) async {
    final current = bestRun;
    if (current == null || current.id == run.id) {
      await recrownBestRunFromDb();
    } else if (run.computeFinalRating() >= current.computeFinalRating()) {
      bestRun = run;
    }
    await _persistBestRunAndCount();
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
  /// Each run is scored with [SchemaRun.computeFinalRating] against its own outcome
  /// snapshot (higher is better), so the comparison honours the outcomes each
  /// run was actually measured with. Returns true when [bestRun] changed — the
  /// signal for the caller to persist the experiment.
  bool updateBestRun(SchemaRun run) {
    final current = bestRun;

    if (current != null &&
        run.computeFinalRating() <= current.computeFinalRating()) {
      return false;
    }

    bestRun = run;
    return true;
  }

  factory SchemaExperiment.fromJson(Map<String, dynamic> json) => _$SchemaExperimentFromJson(json);
  Map<String, dynamic> toJson() => _$SchemaExperimentToJson(this);
}
