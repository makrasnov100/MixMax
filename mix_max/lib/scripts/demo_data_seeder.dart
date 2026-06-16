import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/popup_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// One-off store-screenshot helper: fills the signed-in account with a spread of
/// believable, fully-populated experiments so the App Store / Play Store shots
/// show a lived-in app instead of an empty state.
///
/// This is **not** wired into the shipping UI — it is triggered by the
/// commented-out "Seed demo data" button in `experiments_list_page.dart`, which
/// is meant to be commented in only when capturing screenshots and removed
/// again afterwards. Everything it writes lands in the normal Firestore
/// collections under the current user, so it can be deleted from the account
/// like any hand-made experiment.
///
/// The seeded set deliberately spans different subjects (tea, running, studying,
/// first dates, espresso) and exercises every [ParameterType] — number,
/// duration, temperature, toggle, choice and order — with one experiment
/// carrying eight parameters. Each experiment ships several completed runs with
/// a cached best run, so cards, history and the optimizer all have real data to
/// render; the espresso experiment carries 120 runs to exercise the
/// large-history paths (pagination, scrolling, big run counts).
///
/// Which experiments get written is controllable via the `include` set, so a
/// screenshot pass can seed just the ones it needs — see [seed] and
/// [DemoSeedButton].
class DemoDataSeeder {
  DemoDataSeeder._();

  /// The maps each [DemoExperiment] to the builder that produces it. Iterated in
  /// enum-declaration order so the on-screen (newest-first) list matches the
  /// order experiments are declared here.
  static final Map<DemoExperiment, _ExperimentBuilder> _builders = {
    DemoExperiment.tea: _teaExperiment,
    DemoExperiment.running: _runningExperiment,
    DemoExperiment.study: _studyExperiment,
    DemoExperiment.date: _dateExperiment,
    DemoExperiment.espresso: _espressoExperiment,
  };

  /// Builds the demo experiments named in [include] (default: all of them) and
  /// their runs and writes them all to Firestore under the signed-in user.
  /// Throws if no real user is resolved yet (the caller surfaces that as a
  /// toast).
  static Future<void> seed({Set<DemoExperiment>? include}) async {
    final userId = getIt<AuthService>().user.id;
    if (userId.isEmpty || userId == 'INITIAL') {
      throw StateError('Not signed in yet — open the app fully, then retry.');
    }

    final selected = include ?? DemoExperiment.values.toSet();
    // Keep enum-declaration order regardless of how the set was built, so the
    // staggered timestamps below match the order experiments are declared.
    final ordered =
        DemoExperiment.values.where(selected.contains).toList();

    // Stagger creation timestamps so the list orders naturally (newest first)
    // and the runs look like they were logged over the past few weeks. The list
    // is sorted newest-first, so seeding the first builder most recently puts it
    // at the top — i.e. the on-screen order matches the enum order above
    // ("Perfect cup of tea" first, espresso last).
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const daySeconds = 86400;

    final batch = <_SeededExperiment>[];
    for (var i = 0; i < ordered.length; i++) {
      // Earlier builders are created more recently, so they sit higher up.
      final createdAt = nowSeconds - (i + 1) * 2 * daySeconds;
      batch.add(_builders[ordered[i]]!(userId, createdAt));
    }

    for (final seeded in batch) {
      for (final run in seeded.runs) {
        await DatabaseService.runsRef.doc(run.id).set(run);
      }
      await seeded.experiment.save();
    }
  }

  // ---------------------------------------------------------------------------
  // Shared run construction
  // ---------------------------------------------------------------------------

  /// Builds a completed run against [parameters] / [outcomes] snapshots, freezing
  /// its [SchemaRun.finalRating] the same way the record-outcomes flow does so
  /// the best-run caching and optimizer behave exactly as in real usage.
  static SchemaRun _run({
    required String id,
    required String experimentId,
    required String userId,
    required int createdAt,
    required Map<String, dynamic> parameterValues,
    required Map<String, double> outcomeValues,
    required List<SchemaParameter> parameters,
    required List<SchemaOutcome> outcomes,
  }) {
    final run = SchemaRun(
      id: id,
      experimentId: experimentId,
      userId: userId,
      parameterValues: parameterValues,
      outcomeValues: outcomeValues,
      // Deep-clone the snapshots so each run keeps its own copy.
      parameters:
          parameters.map((p) => SchemaParameter.fromJson(p.toJson())).toList(),
      outcomes:
          outcomes.map((o) => SchemaOutcome.fromJson(o.toJson())).toList(),
      createdAt: createdAt,
      completedAt: createdAt + 3600,
    );
    run.finalRating = run.computeFinalRating();
    return run;
  }

  /// Assembles an experiment from its parts, caching the highest-scoring run as
  /// [SchemaExperiment.bestRun] and the run total, like the live record flow.
  static _SeededExperiment _assemble({
    required String id,
    required String userId,
    required String name,
    required int createdAt,
    required List<SchemaParameter> parameters,
    required List<SchemaOutcome> outcomes,
    required List<SchemaRun> runs,
  }) {
    SchemaRun? best;
    for (final run in runs) {
      if (best == null ||
          run.computeFinalRating() > best.computeFinalRating()) {
        best = run;
      }
    }

    final experiment = SchemaExperiment(
      id: id,
      userId: userId,
      name: name,
      parameters: parameters,
      outcomes: outcomes,
      bestRun: best,
      runCount: runs.length,
      createdAt: createdAt,
    );
    return _SeededExperiment(experiment, runs);
  }

  // ---------------------------------------------------------------------------
  // Experiment 1 — "Perfect cup of tea" (temperature, duration, number, choice,
  // toggle). Five parameters, three outcomes.
  // ---------------------------------------------------------------------------

  static _SeededExperiment _teaExperiment(String userId, int createdAt) {
    final expId = DatabaseService.experimentsRef.doc().id;
    const tempId = 'tea_temp';
    const steepId = 'tea_steep';
    const leafId = 'tea_leaf';
    const typeId = 'tea_type';
    const milkId = 'tea_milk';

    final parameters = <SchemaParameter>[
      SchemaParameter(
        id: tempId,
        name: 'Water temperature',
        type: ParameterType.temperature,
        unit: TemperatureUnit.celsius.label,
        min: 70,
        max: 100,
        increment: 1,
      ),
      SchemaParameter(
        id: steepId,
        name: 'Steep time',
        type: ParameterType.duration,
        unit: DurationUnit.minutes.label,
        min: 1,
        max: 8,
        increment: 0.5,
      ),
      SchemaParameter(
        id: leafId,
        name: 'Leaf amount',
        type: ParameterType.number,
        unit: 'g',
        min: 2,
        max: 8,
        increment: 0.5,
      ),
      SchemaParameter(
        id: typeId,
        name: 'Tea type',
        type: ParameterType.choice,
        options: const ['Green', 'Black', 'Oolong', 'White'],
      ),
      SchemaParameter(
        id: milkId,
        name: 'Splash of milk',
        type: ParameterType.toggle,
        onLabel: 'With milk',
        offLabel: 'No milk',
      ),
    ];

    final outcomes = <SchemaOutcome>[
      SchemaOutcome(
        id: 'tea_flavor',
        name: 'Flavor',
        description: 'How rich and satisfying the cup tastes.',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 50,
      ),
      SchemaOutcome(
        id: 'tea_bitter',
        name: 'Bitterness',
        description: 'Harsh, astringent edge — lower is better.',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.minimize,
        weight: 30,
      ),
      SchemaOutcome(
        id: 'tea_aroma',
        name: 'Aroma',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 20,
      ),
    ];

    SchemaRun mk(
      int dayOffset,
      double temp,
      double steep,
      double leaf,
      String type,
      bool milk,
      double flavor,
      double bitter,
      double aroma,
    ) {
      return _run(
        id: DatabaseService.runsRef.doc().id,
        experimentId: expId,
        userId: userId,
        createdAt: createdAt + dayOffset * 86400,
        parameterValues: {
          tempId: temp,
          steepId: steep,
          leafId: leaf,
          typeId: type,
          milkId: milk,
        },
        outcomeValues: {
          'tea_flavor': flavor,
          'tea_bitter': bitter,
          'tea_aroma': aroma,
        },
        parameters: parameters,
        outcomes: outcomes,
      );
    }

    final runs = [
      mk(0, 95, 5.0, 4.0, 'Black', false, 6, 6, 5),
      mk(1, 80, 3.0, 3.0, 'Green', false, 5, 3, 6),
      mk(2, 85, 4.0, 5.0, 'Oolong', false, 8, 3, 8),
      mk(3, 100, 6.0, 6.0, 'Black', true, 7, 7, 4),
      mk(4, 88, 4.5, 5.0, 'Oolong', false, 9, 2, 9),
    ];

    return _assemble(
      id: expId,
      userId: userId,
      name: 'Perfect Cup of Tea',
      createdAt: createdAt,
      parameters: parameters,
      outcomes: outcomes,
      runs: runs,
    );
  }

  // ---------------------------------------------------------------------------
  // Experiment 2 — "Morning run performance" (the 8+ parameter showcase: number,
  // duration, choice, toggle and order). Nine parameters, three outcomes.
  // ---------------------------------------------------------------------------

  static _SeededExperiment _runningExperiment(String userId, int createdAt) {
    final expId = DatabaseService.experimentsRef.doc().id;
    const distId = 'run_dist';
    const warmId = 'run_warm';
    const paceId = 'run_pace';
    const hydrationId = 'run_hydration';
    const mealId = 'run_meal';
    const bpmId = 'run_bpm';
    const shoeId = 'run_shoe';
    const caffeineId = 'run_caffeine';
    const stretchId = 'run_stretch';

    final parameters = <SchemaParameter>[
      SchemaParameter(
        id: distId,
        name: 'Distance',
        type: ParameterType.number,
        unit: 'km',
        min: 3,
        max: 15,
        increment: 0.5,
      ),
      SchemaParameter(
        id: warmId,
        name: 'Warm-up',
        type: ParameterType.duration,
        unit: DurationUnit.minutes.label,
        min: 0,
        max: 20,
        increment: 1,
      ),
      SchemaParameter(
        id: paceId,
        name: 'Target pace',
        type: ParameterType.number,
        unit: 'min/km',
        min: 4,
        max: 8,
        increment: 0.1,
      ),
      SchemaParameter(
        id: hydrationId,
        name: 'Pre-run water',
        type: ParameterType.number,
        unit: 'ml',
        min: 0,
        max: 750,
        increment: 50,
      ),
      SchemaParameter(
        id: mealId,
        name: 'Pre-run fuel',
        type: ParameterType.choice,
        options: const ['Nothing', 'Banana', 'Oatmeal', 'Energy gel'],
      ),
      SchemaParameter(
        id: bpmId,
        name: 'Playlist tempo',
        type: ParameterType.number,
        unit: 'BPM',
        min: 120,
        max: 180,
        increment: 5,
      ),
      SchemaParameter(
        id: shoeId,
        name: 'Shoes',
        type: ParameterType.choice,
        options: const ['Cushioned', 'Minimal', 'Trail'],
      ),
      SchemaParameter(
        id: caffeineId,
        name: 'Pre-run coffee',
        type: ParameterType.toggle,
        onLabel: 'Caffeinated',
        offLabel: 'None',
      ),
      SchemaParameter(
        id: stretchId,
        name: 'Stretch order',
        type: ParameterType.order,
        items: const ['Calves', 'Hamstrings', 'Quads', 'Hips'],
      ),
    ];

    final outcomes = <SchemaOutcome>[
      SchemaOutcome(
        id: 'run_energy',
        name: 'Energy',
        description: 'How strong you felt through the whole run.',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 40,
      ),
      SchemaOutcome(
        id: 'run_soreness',
        name: 'Next-day soreness',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.minimize,
        weight: 30,
      ),
      SchemaOutcome(
        id: 'run_enjoy',
        name: 'Enjoyment',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 30,
      ),
    ];

    SchemaRun mk(
      int dayOffset,
      double dist,
      double warm,
      double pace,
      double hydration,
      String meal,
      double bpm,
      String shoe,
      bool caffeine,
      List<String> stretch,
      double energy,
      double soreness,
      double enjoy,
    ) {
      return _run(
        id: DatabaseService.runsRef.doc().id,
        experimentId: expId,
        userId: userId,
        createdAt: createdAt + dayOffset * 86400,
        parameterValues: {
          distId: dist,
          warmId: warm,
          paceId: pace,
          hydrationId: hydration,
          mealId: meal,
          bpmId: bpm,
          shoeId: shoe,
          caffeineId: caffeine,
          stretchId: stretch,
        },
        outcomeValues: {
          'run_energy': energy,
          'run_soreness': soreness,
          'run_enjoy': enjoy,
        },
        parameters: parameters,
        outcomes: outcomes,
      );
    }

    final runs = [
      mk(
        0,
        5.0,
        5,
        6.0,
        250,
        'Banana',
        150,
        'Cushioned',
        false,
        const ['Calves', 'Hamstrings', 'Quads', 'Hips'],
        6,
        5,
        6,
      ),
      mk(
        2,
        8.0,
        10,
        5.5,
        500,
        'Oatmeal',
        160,
        'Cushioned',
        true,
        const ['Hamstrings', 'Calves', 'Hips', 'Quads'],
        8,
        4,
        7,
      ),
      mk(
        4,
        10.0,
        12,
        5.8,
        500,
        'Energy gel',
        170,
        'Trail',
        true,
        const ['Quads', 'Hamstrings', 'Calves', 'Hips'],
        7,
        7,
        8,
      ),
      mk(
        6,
        6.0,
        8,
        6.2,
        350,
        'Banana',
        155,
        'Minimal',
        false,
        const ['Calves', 'Quads', 'Hamstrings', 'Hips'],
        5,
        6,
        5,
      ),
      mk(
        8,
        8.0,
        10,
        5.6,
        500,
        'Oatmeal',
        165,
        'Cushioned',
        true,
        const ['Hamstrings', 'Calves', 'Quads', 'Hips'],
        9,
        3,
        9,
      ),
    ];

    return _assemble(
      id: expId,
      userId: userId,
      name: 'Morning Run Performance',
      createdAt: createdAt,
      parameters: parameters,
      outcomes: outcomes,
      runs: runs,
    );
  }

  // ---------------------------------------------------------------------------
  // Experiment 3 — "Focused study session" (duration, choice, toggle,
  // temperature). Five parameters, three outcomes.
  // ---------------------------------------------------------------------------

  static _SeededExperiment _studyExperiment(String userId, int createdAt) {
    final expId = DatabaseService.experimentsRef.doc().id;
    const sessionId = 'study_session';
    const breakId = 'study_break';
    const soundId = 'study_sound';
    const phoneId = 'study_phone';
    const tempId = 'study_temp';

    final parameters = <SchemaParameter>[
      SchemaParameter(
        id: sessionId,
        name: 'Focus block',
        type: ParameterType.duration,
        unit: DurationUnit.minutes.label,
        min: 20,
        max: 90,
        increment: 5,
      ),
      SchemaParameter(
        id: breakId,
        name: 'Break length',
        type: ParameterType.duration,
        unit: DurationUnit.minutes.label,
        min: 3,
        max: 20,
        increment: 1,
      ),
      SchemaParameter(
        id: soundId,
        name: 'Background sound',
        type: ParameterType.choice,
        options: const ['Silence', 'Lo-fi', 'White noise', 'Cafe'],
      ),
      SchemaParameter(
        id: phoneId,
        name: 'Phone out of reach',
        type: ParameterType.toggle,
        onLabel: 'In another room',
        offLabel: 'On the desk',
      ),
      SchemaParameter(
        id: tempId,
        name: 'Room temperature',
        type: ParameterType.temperature,
        unit: TemperatureUnit.fahrenheit.label,
        min: 64,
        max: 76,
        increment: 1,
      ),
    ];

    final outcomes = <SchemaOutcome>[
      SchemaOutcome(
        id: 'study_focus',
        name: 'Focus quality',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 45,
      ),
      SchemaOutcome(
        id: 'study_retain',
        name: 'Material retained',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 35,
      ),
      SchemaOutcome(
        id: 'study_fatigue',
        name: 'Mental fatigue',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.minimize,
        weight: 20,
      ),
    ];

    SchemaRun mk(
      int dayOffset,
      double session,
      double brk,
      String sound,
      bool phone,
      double temp,
      double focus,
      double retain,
      double fatigue,
    ) {
      return _run(
        id: DatabaseService.runsRef.doc().id,
        experimentId: expId,
        userId: userId,
        createdAt: createdAt + dayOffset * 86400,
        parameterValues: {
          sessionId: session,
          breakId: brk,
          soundId: sound,
          phoneId: phone,
          tempId: temp,
        },
        outcomeValues: {
          'study_focus': focus,
          'study_retain': retain,
          'study_fatigue': fatigue,
        },
        parameters: parameters,
        outcomes: outcomes,
      );
    }

    final runs = [
      mk(0, 60, 10, 'Silence', false, 72, 6, 6, 5),
      mk(1, 45, 5, 'Lo-fi', true, 70, 8, 7, 4),
      mk(3, 50, 10, 'White noise', true, 68, 9, 8, 3),
      mk(5, 90, 15, 'Cafe', false, 74, 5, 6, 7),
    ];

    return _assemble(
      id: expId,
      userId: userId,
      name: 'Focused Study Session',
      createdAt: createdAt,
      parameters: parameters,
      outcomes: outcomes,
      runs: runs,
    );
  }

  // ---------------------------------------------------------------------------
  // Experiment 4 — "First date plan" (choice, duration, number). Four
  // parameters, three outcomes.
  // ---------------------------------------------------------------------------

  static _SeededExperiment _dateExperiment(String userId, int createdAt) {
    final expId = DatabaseService.experimentsRef.doc().id;
    const activityId = 'date_activity';
    const lengthId = 'date_length';
    const timeId = 'date_time';
    const budgetId = 'date_budget';

    final parameters = <SchemaParameter>[
      SchemaParameter(
        id: activityId,
        name: 'Activity',
        type: ParameterType.choice,
        options: const [
          'Coffee',
          'Dinner',
          'Walk in the park',
          'Museum',
          'Live music',
        ],
      ),
      SchemaParameter(
        id: lengthId,
        name: 'Planned length',
        type: ParameterType.duration,
        unit: DurationUnit.hours.label,
        min: 1,
        max: 4,
        increment: 0.5,
      ),
      SchemaParameter(
        id: timeId,
        name: 'Time of day',
        type: ParameterType.choice,
        options: const ['Morning', 'Afternoon', 'Evening'],
      ),
      SchemaParameter(
        id: budgetId,
        name: 'Budget',
        type: ParameterType.number,
        unit: '\$',
        min: 0,
        max: 150,
        increment: 5,
      ),
    ];

    final outcomes = <SchemaOutcome>[
      SchemaOutcome(
        id: 'date_connection',
        name: 'Connection',
        description: 'How easily the conversation flowed.',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 50,
      ),
      SchemaOutcome(
        id: 'date_comfort',
        name: 'Comfort',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 30,
      ),
      SchemaOutcome(
        id: 'date_cost',
        name: 'Cost',
        description: 'Total spend — lower is better.',
        min: 0,
        max: 150,
        step: 5,
        goal: OutcomeGoal.minimize,
        weight: 20,
      ),
    ];

    SchemaRun mk(
      int dayOffset,
      String activity,
      double length,
      String time,
      double budget,
      double connection,
      double comfort,
      double cost,
    ) {
      return _run(
        id: DatabaseService.runsRef.doc().id,
        experimentId: expId,
        userId: userId,
        createdAt: createdAt + dayOffset * 86400,
        parameterValues: {
          activityId: activity,
          lengthId: length,
          timeId: time,
          budgetId: budget,
        },
        outcomeValues: {
          'date_connection': connection,
          'date_comfort': comfort,
          'date_cost': cost,
        },
        parameters: parameters,
        outcomes: outcomes,
      );
    }

    final runs = [
      mk(0, 'Dinner', 2.0, 'Evening', 90, 7, 6, 90),
      mk(2, 'Coffee', 1.0, 'Afternoon', 15, 6, 8, 15),
      mk(4, 'Walk in the park', 1.5, 'Afternoon', 5, 8, 9, 5),
      mk(6, 'Museum', 2.5, 'Morning', 40, 9, 8, 40),
    ];

    return _assemble(
      id: expId,
      userId: userId,
      name: 'Ideal Date Night',
      createdAt: createdAt,
      parameters: parameters,
      outcomes: outcomes,
      runs: runs,
    );
  }

  // ---------------------------------------------------------------------------
  // Experiment 5 — "Dialing in espresso" (number, temperature, duration, choice,
  // toggle). The large-history showcase: 120 generated runs so pagination,
  // scrolling and big run-count displays all have real data to render. Runs are
  // generated around a sweet spot so the optimizer still has a clear best run.
  // ---------------------------------------------------------------------------

  static _SeededExperiment _espressoExperiment(String userId, int createdAt) {
    final expId = DatabaseService.experimentsRef.doc().id;
    const doseId = 'esp_dose';
    const grindId = 'esp_grind';
    const tempId = 'esp_temp';
    const shotId = 'esp_shot';
    const basketId = 'esp_basket';
    const spritzId = 'esp_spritz';

    final parameters = <SchemaParameter>[
      SchemaParameter(
        id: doseId,
        name: 'Dose',
        type: ParameterType.number,
        unit: 'g',
        min: 14,
        max: 20,
        increment: 0.5,
      ),
      SchemaParameter(
        id: grindId,
        name: 'Grind setting',
        type: ParameterType.number,
        min: 1,
        max: 30,
        increment: 1,
      ),
      SchemaParameter(
        id: tempId,
        name: 'Brew temperature',
        type: ParameterType.temperature,
        unit: TemperatureUnit.celsius.label,
        min: 88,
        max: 96,
        increment: 1,
      ),
      SchemaParameter(
        id: shotId,
        name: 'Shot time',
        type: ParameterType.duration,
        unit: DurationUnit.seconds.label,
        min: 20,
        max: 40,
        increment: 1,
      ),
      SchemaParameter(
        id: basketId,
        name: 'Basket',
        type: ParameterType.choice,
        options: const ['Single', 'Double', 'Ridgeless'],
      ),
      SchemaParameter(
        id: spritzId,
        name: 'WDT + spritz',
        type: ParameterType.toggle,
        onLabel: 'Spritzed',
        offLabel: 'Dry',
      ),
    ];

    final outcomes = <SchemaOutcome>[
      SchemaOutcome(
        id: 'esp_taste',
        name: 'Taste',
        description: 'Overall sweetness and balance in the cup.',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 50,
      ),
      SchemaOutcome(
        id: 'esp_bitter',
        name: 'Bitterness',
        description: 'Harsh, ashy edge — lower is better.',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.minimize,
        weight: 30,
      ),
      SchemaOutcome(
        id: 'esp_crema',
        name: 'Crema',
        min: 0,
        max: 10,
        step: 1,
        goal: OutcomeGoal.maximize,
        weight: 20,
      ),
    ];

    // A triangular falloff: 1 at [ideal], dropping to 0 once [x] is [tol] away.
    double bell(double x, double ideal, double tol) =>
        (1 - (x - ideal).abs() / tol).clamp(0.0, 1.0);

    const baskets = ['Single', 'Double', 'Ridgeless'];
    const runCount = 120;
    const stepSeconds = 43200; // ~12 h between logged shots

    final runs = <SchemaRun>[];
    for (var i = 0; i < runCount; i++) {
      // Walk each parameter across its range on a different stride so the runs
      // cover the space without ever leaving the increment grid.
      final dose = 14 + (i % 13) * 0.5; // 14.0 .. 20.0
      final grind = (1 + (i * 7) % 30).toDouble(); // 1 .. 30
      final temp = (88 + i % 9).toDouble(); // 88 .. 96
      final shot = (20 + (i * 3) % 21).toDouble(); // 20 .. 40
      final basket = baskets[i % baskets.length];
      final spritz = i % 2 == 0;

      // Sweet spot: 18 g, grind 15, 93 °C, 28 s — shots near it score best, so
      // the cached best run and optimizer behave like a real dial-in.
      final quality = (bell(dose, 18, 6) +
              bell(grind, 15, 14) +
              bell(temp, 93, 6) +
              bell(shot, 28, 12)) /
          4;

      runs.add(
        _run(
          id: DatabaseService.runsRef.doc().id,
          experimentId: expId,
          userId: userId,
          // Newest shot lands on the experiment's createdAt; the rest trail back
          // into the past so all 120 timestamps stay before "now".
          createdAt: createdAt - (runCount - 1 - i) * stepSeconds,
          parameterValues: {
            doseId: dose,
            grindId: grind,
            tempId: temp,
            shotId: shot,
            basketId: basket,
            spritzId: spritz,
          },
          outcomeValues: {
            'esp_taste': (2 + 8 * quality).roundToDouble(),
            'esp_bitter': (8 - 6 * quality).roundToDouble(),
            'esp_crema': (3 + 7 * quality).roundToDouble(),
          },
          parameters: parameters,
          outcomes: outcomes,
        ),
      );
    }

    return _assemble(
      id: expId,
      userId: userId,
      name: 'Dialing In Espresso',
      createdAt: createdAt,
      parameters: parameters,
      outcomes: outcomes,
      runs: runs,
    );
  }
}

/// Identifies each demo experiment the seeder can produce, so callers can pick a
/// subset via [DemoDataSeeder.seed]'s `include` set. Declared in the order the
/// experiments should appear in the list (newest-first on screen).
enum DemoExperiment { tea, running, study, date, espresso }

/// One built experiment plus the runs that belong to it, waiting to be written.
typedef _ExperimentBuilder =
    _SeededExperiment Function(String userId, int createdAt);

class _SeededExperiment {
  final SchemaExperiment experiment;
  final List<SchemaRun> runs;

  const _SeededExperiment(this.experiment, this.runs);
}

/// Self-contained gold action that runs [DemoDataSeeder.seed], showing a spinner
/// inside itself while writing and a result toast when done. Kept here next to
/// the seeder so the whole store-screenshot helper is one commented-in import.
///
/// Drop `const DemoSeedButton()` into the experiments-list footer (it is already
/// there, commented out) when you need to populate an account for screenshots.
/// Pass [include] to seed only some of them, e.g.
/// `DemoSeedButton(include: {DemoExperiment.espresso})` for just the big-history
/// one.
class DemoSeedButton extends StatefulWidget {
  /// Which demo experiments this button creates. Defaults to all of them.
  final Set<DemoExperiment> include;

  const DemoSeedButton({
    super.key,
    this.include = const {
      DemoExperiment.tea,
      DemoExperiment.running,
      DemoExperiment.study,
      DemoExperiment.date,
      DemoExperiment.espresso,
    },
  });

  @override
  State<DemoSeedButton> createState() => _DemoSeedButtonState();
}

class _DemoSeedButtonState extends State<DemoSeedButton> {
  bool _seeding = false;

  Future<void> _onPressed() async {
    if (_seeding) return;
    setState(() => _seeding = true);
    try {
      await DemoDataSeeder.seed(include: widget.include);
      PopupService.showResultToast(
        message: '✅ Demo experiments created.',
        backgroundColor: AppColors.addGreen,
      );
    } catch (e) {
      PopupService.showResultToast(
        message: '❌ Could not seed demo data: $e',
        backgroundColor: AppColors.dangerRed,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MixMaxButton(
      label: _seeding ? 'Creating demo data…' : 'Seed demo data',
      variant: MixMaxButtonVariant.gold,
      enabled: !_seeding,
      onPressed: _onPressed,
      leading:
          _seeding
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : null,
    );
  }
}
