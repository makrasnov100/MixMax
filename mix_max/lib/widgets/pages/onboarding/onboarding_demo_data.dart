import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';

/// In-memory sample data for the onboarding tour.
///
/// The tour drives the *real* app screens (experiments list, details, suggested
/// run) but feeds them this hand-built "Cold brew coffee" experiment instead of
/// the user's Firestore data. Nothing here is ever saved — it is constructed
/// fresh each time the tour starts and discarded when it ends, so it never
/// clutters the user's account or touches the network.
class OnboardingDemoData {
  OnboardingDemoData._();

  // Stable ids so a run's recorded values line up with the parameter / outcome
  // definitions when the screens render them.
  static const String experimentId = '__demo_experiment__';
  static const String coffeeId = 'demo_coffee';
  static const String steepId = 'demo_steep';
  static const String strengthId = 'demo_strength';
  static const String bitternessId = 'demo_bitterness';

  /// The next-run suggestion shown on the suggested-run step, keyed by parameter
  /// id. Hard-coded so the tour shows a believable "informed" pick without
  /// running the optimizer or reading any past runs.
  static const Map<String, dynamic> suggestion = <String, dynamic>{
    coffeeId: 85.0,
    steepId: 16.0,
  };

  static List<SchemaParameter> _parameters() => [
        SchemaParameter(
          id: coffeeId,
          name: 'Coffee',
          type: ParameterType.number,
          unit: 'g',
          min: 40,
          max: 120,
          increment: 5,
        ),
        SchemaParameter(
          id: steepId,
          name: 'Steep time',
          type: ParameterType.number,
          unit: 'h',
          min: 6,
          max: 24,
          increment: 1,
        ),
      ];

  static List<SchemaOutcome> _outcomes() => [
        SchemaOutcome(
          id: strengthId,
          name: 'Strength',
          min: 0,
          max: 10,
          step: 1,
          goal: OutcomeGoal.maximize,
          weight: 60,
        ),
        SchemaOutcome(
          id: bitternessId,
          name: 'Bitterness',
          min: 0,
          max: 10,
          step: 1,
          goal: OutcomeGoal.minimize,
          weight: 40,
        ),
      ];

  /// Builds a single completed run, stamping its frozen [SchemaRun.finalRating]
  /// from the same scoring the app uses so the best run is chosen consistently.
  static SchemaRun _run({
    required String id,
    required double coffee,
    required double steep,
    required double strength,
    required double bitterness,
    required List<SchemaParameter> parameters,
    required List<SchemaOutcome> outcomes,
  }) {
    final run = SchemaRun(
      id: id,
      experimentId: experimentId,
      userId: 'demo',
      parameterValues: {coffeeId: coffee, steepId: steep},
      outcomeValues: {strengthId: strength, bitternessId: bitterness},
      parameters: parameters,
      outcomes: outcomes,
      createdAt: 0,
      completedAt: 0,
    );
    run.finalRating = run.computeFinalRating();
    return run;
  }

  /// A fresh sample experiment with two parameters, two outcomes, four completed
  /// runs and a cached best run. Rebuilt on every call so the tour never mutates
  /// shared state.
  static SchemaExperiment experiment() {
    final parameters = _parameters();
    final outcomes = _outcomes();

    final runs = [
      _run(id: 'demo_run_1', coffee: 60, steep: 12, strength: 5, bitterness: 4, parameters: parameters, outcomes: outcomes),
      _run(id: 'demo_run_2', coffee: 90, steep: 18, strength: 7, bitterness: 6, parameters: parameters, outcomes: outcomes),
      // The winner: strong but smooth.
      _run(id: 'demo_run_3', coffee: 80, steep: 14, strength: 8, bitterness: 3, parameters: parameters, outcomes: outcomes),
      _run(id: 'demo_run_4', coffee: 100, steep: 20, strength: 9, bitterness: 8, parameters: parameters, outcomes: outcomes),
    ];

    SchemaRun best = runs.first;
    for (final run in runs) {
      if (run.computeFinalRating() > best.computeFinalRating()) best = run;
    }

    return SchemaExperiment(
      id: experimentId,
      userId: 'demo',
      name: 'Cold brew coffee',
      parameters: parameters,
      outcomes: outcomes,
      bestRun: best,
      runCount: runs.length,
      createdAt: 0,
    );
  }
}
