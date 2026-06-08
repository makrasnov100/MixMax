import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/services/bayesian_optimization_service.dart';

/// Convergence tests for [BayesianOptimizationService].
///
/// Each test defines a synthetic objective with a known optimum, drives the
/// optimisation loop forward by repeatedly asking for the next suggestion and
/// "evaluating" it against the objective, then asserts the best-scoring run
/// is at (or close to) the known optimum.
///
/// The service uses an unseeded [math.Random] internally, so individual runs
/// have some variance. To keep the suite reliable we:
///   • allocate enough BO iterations for the search space at hand, and
///   • retry the loop a small number of times before failing — a single
///     unlucky search shouldn't flake the build.
void main() {
  group('BayesianOptimizationService — single parameter convergence', () {
    test('number parameter converges near the peak', () {
      const optimum = 75.0;
      final experiment = _experimentWithSingleParam(
        SchemaParameter(
          id: 'x',
          name: 'x',
          type: ParameterType.number,
          min: 0,
          max: 100,
        ),
      );

      final best = _runUntilConverged(
        experiment: experiment,
        evaluate: (pv) => _gaussianScore(pv['x'] as double, optimum, sigma: 10),
        numIterations: 30,
        scoreThreshold: 0.85,
      );

      expect(
        best.outcomeValues!['score']!,
        greaterThan(0.85),
        reason: 'BO should locate the peak around x = $optimum',
      );
      expect(
        ((best.parameterValues!['x'] as double) - optimum).abs(),
        lessThan(15),
        reason: 'Best run\'s x should be within ±15 of the true optimum',
      );
    });

    test('duration parameter converges near the peak', () {
      const optimum = 42.0;
      final experiment = _experimentWithSingleParam(
        SchemaParameter(
          id: 'd',
          name: 'd',
          type: ParameterType.duration,
          min: 0,
          max: 120,
        ),
      );

      final best = _runUntilConverged(
        experiment: experiment,
        evaluate: (pv) => _gaussianScore(pv['d'] as double, optimum, sigma: 12),
        numIterations: 30,
        scoreThreshold: 0.85,
      );

      expect(best.outcomeValues!['score']!, greaterThan(0.85));
      expect(
        ((best.parameterValues!['d'] as double) - optimum).abs(),
        lessThan(18),
      );
    });

    test('toggle parameter converges to the optimum boolean', () {
      const optimum = true;
      final experiment = _experimentWithSingleParam(
        SchemaParameter(id: 't', name: 't', type: ParameterType.toggle),
      );

      final best = _runUntilConverged(
        experiment: experiment,
        evaluate: (pv) => pv['t'] == optimum ? 1.0 : 0.0,
        numIterations: 8,
        scoreThreshold: 1.0,
      );

      expect(best.parameterValues!['t'], equals(optimum));
      expect(best.outcomeValues!['score'], equals(1.0));
    });

    test('choice parameter converges to the optimum option', () {
      const optimum = 'green';
      final experiment = _experimentWithSingleParam(
        SchemaParameter(
          id: 'c',
          name: 'c',
          type: ParameterType.choice,
          options: ['red', 'green', 'blue', 'yellow'],
        ),
      );

      final best = _runUntilConverged(
        experiment: experiment,
        evaluate: (pv) {
          final v = pv['c'] as String?;
          if (v == optimum) return 1.0;
          if (v == 'blue') return 0.4;
          return 0.0;
        },
        numIterations: 16,
        scoreThreshold: 1.0,
      );

      expect(best.parameterValues!['c'], equals(optimum));
      expect(best.outcomeValues!['score'], equals(1.0));
    });

    test('order parameter converges to the optimum ordering', () {
      final items = ['A', 'B', 'C'];
      final optimum = ['A', 'B', 'C'];
      final experiment = _experimentWithSingleParam(
        SchemaParameter(
          id: 'o',
          name: 'o',
          type: ParameterType.order,
          items: items,
        ),
      );

      final best = _runUntilConverged(
        experiment: experiment,
        evaluate:
            (pv) => _kendallConcordance(
              (pv['o'] as List).map((e) => e.toString()).toList(),
              optimum,
            ),
        numIterations: 36,
        scoreThreshold: 1.0,
      );

      expect(best.parameterValues!['o'], equals(optimum));
      expect(best.outcomeValues!['score'], equals(1.0));
    });
  });

  group('BayesianOptimizationService — multi-parameter convergence', () {
    test('joint search over multiple numeric parameters converges', () {
      const optimumX = 30.0;
      const optimumY = 70.0;
      const optimumZ = 5.0;

      final experiment = SchemaExperiment(
        id: 'exp',
        parameters: [
          SchemaParameter(
            id: 'x',
            type: ParameterType.number,
            min: 0,
            max: 100,
          ),
          SchemaParameter(
            id: 'y',
            type: ParameterType.number,
            min: 0,
            max: 100,
          ),
          SchemaParameter(
            id: 'z',
            type: ParameterType.duration,
            min: 0,
            max: 30,
          ),
        ],
        outcomes: [_scoreOutcome()],
      );

      double evaluate(Map<String, dynamic> pv) {
        final dx = ((pv['x'] as double) - optimumX) / 20.0;
        final dy = ((pv['y'] as double) - optimumY) / 20.0;
        final dz = ((pv['z'] as double) - optimumZ) / 8.0;
        return math.exp(-0.5 * (dx * dx + dy * dy + dz * dz));
      }

      final best = _runUntilConverged(
        experiment: experiment,
        evaluate: evaluate,
        numIterations: 50,
        scoreThreshold: 0.8,
      );

      expect(
        best.outcomeValues!['score']!,
        greaterThan(0.8),
        reason: 'BO should locate the joint peak in 3-D numeric space',
      );
      expect(
        ((best.parameterValues!['x'] as double) - optimumX).abs(),
        lessThan(20),
      );
      expect(
        ((best.parameterValues!['y'] as double) - optimumY).abs(),
        lessThan(20),
      );
      expect(
        ((best.parameterValues!['z'] as double) - optimumZ).abs(),
        lessThan(10),
      );
    });

    test('BO beats random-search baseline on a 3-D numeric peak', () {
      // Baseline comparison. We average both methods across multiple trials so
      // we're comparing *expected* performance rather than single lucky draws.
      //
      // Empirically (see exploration sweep), with σ = 20 in a 100x100x100
      // search space and a 30-iteration budget:
      //   • random-search mean best ≈ 0.65 (seeded → deterministic)
      //   • BO mean best ≈ 0.95–0.98 (variance ~0.03 across runs)
      // So we assert a comfortable margin of 0.20, well clear of noise.
      const optima = [30.0, 70.0, 50.0];
      const sigma = 20.0;
      const iterations = 30;
      const boTrials = 5;
      const randomTrials = 30;
      const requiredMargin = 0.20;

      final experiment = SchemaExperiment(
        id: 'exp',
        parameters: [
          for (int i = 0; i < optima.length; i++)
            SchemaParameter(
              id: 'p$i',
              type: ParameterType.number,
              min: 0,
              max: 100,
            ),
        ],
        outcomes: [_scoreOutcome()],
      );

      double evaluate(Map<String, dynamic> pv) {
        var sq = 0.0;
        for (int i = 0; i < optima.length; i++) {
          final d = ((pv['p$i'] as double) - optima[i]) / sigma;
          sq += d * d;
        }
        return math.exp(-0.5 * sq);
      }

      // ── BO: average best-score across several trials ──────────────────
      var boMean = 0.0;
      for (int trial = 0; trial < boTrials; trial++) {
        final runs = _runBoLoop(
          experiment: experiment,
          evaluate: evaluate,
          numIterations: iterations,
        );
        boMean += runs
            .map((r) => r.outcomeValues!['score']!)
            .reduce(math.max);
      }
      boMean /= boTrials;

      // ── Random-search baseline: average best-score, seeded so the
      //    baseline is deterministic and the test stays reproducible. ────
      var randomMean = 0.0;
      for (int trial = 0; trial < randomTrials; trial++) {
        final rng = math.Random(trial);
        var best = 0.0;
        for (int i = 0; i < iterations; i++) {
          final pv = <String, dynamic>{
            for (int d = 0; d < optima.length; d++)
              'p$d': rng.nextDouble() * 100.0,
          };
          final s = evaluate(pv);
          if (s > best) best = s;
        }
        randomMean += best;
      }
      randomMean /= randomTrials;

      expect(
        boMean,
        greaterThan(randomMean + requiredMargin),
        reason:
            'BO mean ($boMean) should beat random-search mean ($randomMean) '
            'by at least $requiredMargin on a 3-D Gaussian peak',
      );
    });

    test('cold-start (no past runs) still returns a valid suggestion', () {
      // Edge case: with zero past runs the service falls back to a uniform
      // random suggestion. We don't need to converge here — we just want to
      // know we get back a well-typed value for every parameter.
      final experiment = SchemaExperiment(
        id: 'exp',
        parameters: [
          SchemaParameter(
            id: 'x',
            type: ParameterType.number,
            min: 0,
            max: 100,
          ),
          SchemaParameter(id: 't', type: ParameterType.toggle),
          SchemaParameter(
            id: 'c',
            type: ParameterType.choice,
            options: ['a', 'b'],
          ),
          SchemaParameter(
            id: 'o',
            type: ParameterType.order,
            items: ['x', 'y'],
          ),
        ],
        outcomes: [_scoreOutcome()],
      );

      final suggestion = BayesianOptimizationService.suggestNextParameters(
        experiment: experiment,
        pastRuns: const [],
      );

      expect(suggestion['x'], isA<double>());
      expect(suggestion['x'], inInclusiveRange(0.0, 100.0));
      expect(suggestion['t'], isA<bool>());
      expect(['a', 'b'], contains(suggestion['c']));
      expect(suggestion['o'], unorderedEquals(['x', 'y']));
    });
  });

  group('BayesianOptimizationService — increment snapping', () {
    // A value lands on the grid when (v - min) is a whole multiple of the step.
    void expectOnGrid(num value, {required double min, required double step}) {
      final k = (value - min) / step;
      expect(
        (k - k.roundToDouble()).abs(),
        lessThan(1e-6),
        reason: '$value is not on the min $min + k×$step grid',
      );
    }

    test('cold-start suggestion snaps to the increment grid', () {
      final param = SchemaParameter(
        id: 'x',
        type: ParameterType.number,
        min: 0,
        max: 10,
        increment: 0.5,
      );
      final experiment = _experimentWithSingleParam(param);

      // No past runs → uniform-random fallback path. Sample repeatedly since
      // the draw is random.
      for (int i = 0; i < 50; i++) {
        final s = BayesianOptimizationService.suggestNextParameters(
          experiment: experiment,
          pastRuns: const [],
        );
        final v = s['x'] as double;
        expect(v, inInclusiveRange(0.0, 10.0));
        expectOnGrid(v, min: 0, step: 0.5);
      }
    });

    test('GP-path suggestion snaps to a whole-number (integers-only) grid', () {
      final param = SchemaParameter(
        id: 'x',
        type: ParameterType.number,
        min: 0,
        max: 100,
        increment: 1,
      );
      final experiment = _experimentWithSingleParam(param);

      // Two recorded runs cross the GP threshold, so suggestions come from the
      // decode path rather than the cold-start fallback.
      final runs = _runBoLoop(
        experiment: experiment,
        evaluate: (pv) => _gaussianScore(pv['x'] as double, 60, sigma: 15),
        numIterations: 20,
      );

      for (final r in runs) {
        final v = r.parameterValues!['x'] as double;
        expect(v, inInclusiveRange(0.0, 100.0));
        expectOnGrid(v, min: 0, step: 1);
        expect(v, equals(v.roundToDouble()), reason: 'should be a whole number');
      }
    });

    test('no increment leaves the value smooth (off-grid allowed)', () {
      final param = SchemaParameter(
        id: 'x',
        type: ParameterType.number,
        min: 0,
        max: 1,
      );
      final experiment = _experimentWithSingleParam(param);

      var sawFractional = false;
      for (int i = 0; i < 50 && !sawFractional; i++) {
        final s = BayesianOptimizationService.suggestNextParameters(
          experiment: experiment,
          pastRuns: const [],
        );
        final v = s['x'] as double;
        if ((v - v.roundToDouble()).abs() > 1e-6) sawFractional = true;
      }
      expect(
        sawFractional,
        isTrue,
        reason: 'without an increment, values should not be grid-locked',
      );
    });
  });
}

// ─── Test helpers ──────────────────────────────────────────────────────────

/// Standard "score" outcome used across tests: normalised to [0, 1], higher is
/// better.
SchemaOutcome _scoreOutcome() => SchemaOutcome(
  id: 'score',
  name: 'score',
  min: 0,
  max: 1,
  goal: OutcomeGoal.maximize,
);

/// Convenience builder for a single-parameter experiment.
SchemaExperiment _experimentWithSingleParam(SchemaParameter param) =>
    SchemaExperiment(
      id: 'exp',
      parameters: [param],
      outcomes: [_scoreOutcome()],
    );

/// Drives the BO loop for [numIterations] rounds, evaluating each suggestion
/// against [evaluate] and appending the result to the run history.
List<SchemaRun> _runBoLoop({
  required SchemaExperiment experiment,
  required double Function(Map<String, dynamic>) evaluate,
  required int numIterations,
}) {
  final runs = <SchemaRun>[];
  for (int i = 0; i < numIterations; i++) {
    final next = BayesianOptimizationService.suggestNextParameters(
      experiment: experiment,
      pastRuns: runs,
    );
    runs.add(
      SchemaRun(
        id: 'r$i',
        parameterValues: next,
        outcomeValues: {'score': evaluate(next)},
      ),
    );
  }
  return runs;
}

/// Runs the BO loop with a small retry budget so a single unlucky search
/// doesn't make the build flake. Returns the best run from the best attempt.
SchemaRun _runUntilConverged({
  required SchemaExperiment experiment,
  required double Function(Map<String, dynamic>) evaluate,
  required int numIterations,
  required double scoreThreshold,
  int maxAttempts = 3,
}) {
  SchemaRun? bestEver;
  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    final runs = _runBoLoop(
      experiment: experiment,
      evaluate: evaluate,
      numIterations: numIterations,
    );
    final best = runs.reduce(
      (a, b) =>
          (a.outcomeValues!['score']! >= b.outcomeValues!['score']!) ? a : b,
    );
    if (bestEver == null ||
        best.outcomeValues!['score']! > bestEver.outcomeValues!['score']!) {
      bestEver = best;
    }
    if (best.outcomeValues!['score']! >= scoreThreshold) return best;
  }
  return bestEver!;
}

/// Normal-curve-shaped score in [0, 1] centred at [optimum].
double _gaussianScore(double v, double optimum, {required double sigma}) {
  final d = (v - optimum) / sigma;
  return math.exp(-0.5 * d * d);
}

/// Concordance score for an ordering against a target: fraction of ordered
/// pairs whose relative order matches the target. Returns 1.0 only for the
/// exact target ordering.
double _kendallConcordance(List<String> ordering, List<String> target) {
  final pos = <String, int>{
    for (int i = 0; i < ordering.length; i++) ordering[i]: i,
  };
  int agree = 0;
  int total = 0;
  for (int i = 0; i < target.length; i++) {
    for (int j = i + 1; j < target.length; j++) {
      final a = pos[target[i]];
      final b = pos[target[j]];
      if (a == null || b == null) continue;
      total++;
      if (a < b) agree++;
    }
  }
  return total == 0 ? 0.0 : agree / total;
}
