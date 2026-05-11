import 'dart:math' as math;

import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';

/// Suggests the next set of parameter values for an experiment using
/// Bayesian optimisation (Gaussian Process surrogate + Expected Improvement).
///
/// Usage:
/// ```dart
/// final suggestion = BayesianOptimizationService.suggestNextParameters(
///   experiment: myExperiment,
///   pastRuns: completedRuns,
/// );
/// ```
class BayesianOptimizationService {
  // ── GP hyper-parameters (normalised feature space [0, 1]) ──────────────────
  static const double _lengthScale = 0.5;
  static const double _signalVariance = 1.0;
  static const double _noise = 1e-3;

  // ── Acquisition hyper-parameters ──────────────────────────────────────────
  /// Number of random candidates evaluated during acquisition optimisation.
  static const int _numCandidates = 500;

  /// Exploration bonus ξ in Expected Improvement.
  static const double _xi = 0.01;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a map from parameterId → suggested value for the next run.
  ///
  /// Falls back to a uniform-random suggestion when fewer than 2 valid past
  /// runs are available, since a GP requires at least 2 observations to be
  /// meaningful.
  static Map<String, dynamic> suggestNextParameters({
    required SchemaExperiment experiment,
    required List<SchemaRun> pastRuns,
  }) {
    final parameters = experiment.parameters ?? [];
    final outcomes = experiment.outcomes ?? [];

    if (parameters.isEmpty) return {};

    final rng = math.Random();

    // Require at least 2 runs with complete data before using the GP.
    final validRuns = _filterValidRuns(parameters, outcomes, pastRuns);
    if (validRuns.length < 2) {
      return _randomSuggestion(parameters, rng);
    }

    // Encode past runs into a normalised feature matrix and objective vector.
    final X = validRuns
        .map((r) => _encodeParameters(parameters, r.parameterValues!))
        .toList();
    final y = validRuns
        .map((r) => _computeObjective(outcomes, r.outcomeValues!))
        .toList();

    final gp = _GaussianProcess(
      lengthScale: _lengthScale,
      signalVariance: _signalVariance,
      noise: _noise,
    )..fit(X, y);

    final fBest = y.reduce(math.max);
    final featureDim = X.first.length;

    // Random search over the acquisition function.
    var bestCandidate = List<double>.filled(featureDim, 0.0);
    var bestEI = double.negativeInfinity;

    for (int i = 0; i < _numCandidates; i++) {
      final candidate = _sampleCandidate(parameters, rng);
      final pred = gp.predict(candidate);
      final ei = _expectedImprovement(pred.mean, pred.stdDev, fBest);
      if (ei > bestEI) {
        bestEI = ei;
        bestCandidate = candidate;
      }
    }

    return _decodeParameters(parameters, bestCandidate);
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  static List<SchemaRun> _filterValidRuns(
    List<SchemaParameter> parameters,
    List<SchemaOutcome> outcomes,
    List<SchemaRun> runs,
  ) {
    return runs.where((r) {
      final pv = r.parameterValues ?? {};
      final ov = r.outcomeValues ?? {};
      final hasAllParams = parameters.every((p) => pv.containsKey(p.id));
      final hasAnyOutcome = outcomes.any((o) => ov.containsKey(o.id));
      return hasAllParams && hasAnyOutcome;
    }).toList();
  }

  // ── Feature encoding ───────────────────────────────────────────────────────

  /// Encodes all parameter values into a flat normalised vector in [0, 1].
  ///
  /// Dimension breakdown per ParameterType:
  ///   number / duration → 1            (linearly scaled by [min, max])
  ///   toggle            → 1            (false = 0.0, true = 1.0)
  ///   choice (n opts)   → max(n, 1)    (one-hot; unknown value → all zeros)
  ///   order  (n items)  → n            (position of each item / (n−1))
  static List<double> _encodeParameters(
    List<SchemaParameter> parameters,
    Map<String, dynamic> values,
  ) {
    final features = <double>[];

    for (final param in parameters) {
      final raw = values[param.id];

      switch (param.type) {
        case ParameterType.number:
        case ParameterType.duration:
          final v = (raw as num?)?.toDouble() ?? 0.0;
          final lo = param.min ?? 0.0;
          final hi = param.max ?? 1.0;
          features.add(hi > lo ? (v - lo) / (hi - lo) : 0.5);

        case ParameterType.toggle:
          features.add(raw == true ? 1.0 : 0.0);

        case ParameterType.choice:
          final options = param.options ?? [];
          if (options.isEmpty) {
            // Keep one slot so encode/decode cursors stay in lock-step.
            features.add(0.0);
          } else {
            final selected = raw?.toString() ?? '';
            final idx = options.indexOf(selected);
            for (int i = 0; i < options.length; i++) {
              features.add(i == idx ? 1.0 : 0.0);
            }
          }

        case ParameterType.order:
          final items = param.items ?? [];
          final ordering =
              (raw as List?)?.map((e) => e.toString()).toList() ?? List<String>.from(items);
          for (final item in items) {
            final pos = ordering.indexOf(item).clamp(0, items.length - 1);
            features.add(items.length > 1 ? pos / (items.length - 1) : 0.0);
          }

        case null:
          features.add(0.0);
      }
    }

    return features;
  }

  /// Decodes a normalised feature vector back into typed parameter values.
  static Map<String, dynamic> _decodeParameters(
    List<SchemaParameter> parameters,
    List<double> features,
  ) {
    final result = <String, dynamic>{};
    int cursor = 0;

    for (final param in parameters) {
      switch (param.type) {
        case ParameterType.number:
        case ParameterType.duration:
          final v = features[cursor++].clamp(0.0, 1.0);
          final lo = param.min ?? 0.0;
          final hi = param.max ?? 1.0;
          result[param.id] = lo + v * (hi - lo);

        case ParameterType.toggle:
          result[param.id] = features[cursor++] >= 0.5;

        case ParameterType.choice:
          final options = param.options ?? [];
          if (options.isEmpty) {
            result[param.id] = null;
            cursor++;
          } else {
            // Argmax over the one-hot slice; robust to any non-one-hot input
            // because we just pick the strongest dimension.
            int bestIdx = 0;
            double bestVal = double.negativeInfinity;
            for (int i = 0; i < options.length; i++) {
              final v = features[cursor++];
              if (v > bestVal) {
                bestVal = v;
                bestIdx = i;
              }
            }
            result[param.id] = options[bestIdx];
          }

        case ParameterType.order:
          final items = param.items ?? [];
          if (items.isEmpty) {
            result[param.id] = <String>[];
          } else {
            final positions = <double>[];
            for (int i = 0; i < items.length; i++) {
              positions.add(features[cursor++].clamp(0.0, 1.0));
            }
            // Re-order items by their decoded positions (ascending).
            final indexed = List.generate(items.length, (i) => (i, positions[i]));
            indexed.sort((a, b) => a.$2.compareTo(b.$2));
            result[param.id] = indexed.map((e) => items[e.$1]).toList();
          }

        case null:
          result[param.id] = null;
          cursor++;
      }
    }

    return result;
  }

  // ── Objective ──────────────────────────────────────────────────────────────

  /// Combines all observed outcome values into a single scalar the GP
  /// maximises (higher = better).
  ///
  /// Each outcome is normalised to [0, 1] using its declared bounds and then
  /// flipped when the goal is to minimise.  Multiple outcomes are averaged.
  static double _computeObjective(
    List<SchemaOutcome> outcomes,
    Map<String, double> outcomeValues,
  ) {
    if (outcomes.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    for (final outcome in outcomes) {
      final value = outcomeValues[outcome.id];
      if (value == null) continue;

      final lo = outcome.min;
      final hi = outcome.max;

      double normalised;
      if (lo != null && hi != null && hi > lo) {
        normalised = ((value - lo) / (hi - lo)).clamp(0.0, 1.0);
      } else {
        // No declared bounds — use the raw value directly.
        normalised = value;
      }

      // GP maximises, so invert when the goal is to minimise.
      if (outcome.goal == OutcomeGoal.minimize) {
        normalised = 1.0 - normalised;
      }

      total += normalised;
      count++;
    }

    return count > 0 ? total / count : 0.0;
  }

  // ── Cold-start fallback ────────────────────────────────────────────────────

  static Map<String, dynamic> _randomSuggestion(
    List<SchemaParameter> parameters,
    math.Random rng,
  ) {
    final result = <String, dynamic>{};

    for (final param in parameters) {
      switch (param.type) {
        case ParameterType.number:
        case ParameterType.duration:
          final lo = param.min ?? 0.0;
          final hi = param.max ?? 1.0;
          result[param.id] = lo + rng.nextDouble() * (hi - lo);

        case ParameterType.toggle:
          result[param.id] = rng.nextBool();

        case ParameterType.choice:
          final options = param.options ?? [];
          if (options.isNotEmpty) {
            result[param.id] = options[rng.nextInt(options.length)];
          }

        case ParameterType.order:
          final items = List<String>.from(param.items ?? []);
          items.shuffle(rng);
          result[param.id] = items;

        case null:
          break;
      }
    }

    return result;
  }

  // ── Candidate sampling ─────────────────────────────────────────────────────

  /// Samples a single candidate in the GP's feature space, respecting the
  /// discrete structure of each parameter:
  ///   number / duration → uniform in [0, 1]
  ///   toggle            → {0.0, 1.0}
  ///   choice            → one-hot over options
  ///   order             → rank vector of a real random permutation
  ///
  /// This guarantees every acquisition evaluation happens at a legal point,
  /// instead of wasting candidates on impossible interpolations.
  static List<double> _sampleCandidate(
    List<SchemaParameter> parameters,
    math.Random rng,
  ) {
    final candidate = <double>[];

    for (final param in parameters) {
      switch (param.type) {
        case ParameterType.number:
        case ParameterType.duration:
          candidate.add(rng.nextDouble());

        case ParameterType.toggle:
          candidate.add(rng.nextBool() ? 1.0 : 0.0);

        case ParameterType.choice:
          final options = param.options ?? [];
          if (options.isEmpty) {
            candidate.add(0.0);
          } else {
            final pick = rng.nextInt(options.length);
            for (int i = 0; i < options.length; i++) {
              candidate.add(i == pick ? 1.0 : 0.0);
            }
          }

        case ParameterType.order:
          final items = param.items ?? [];
          if (items.isEmpty) break;
          final indices = List<int>.generate(items.length, (i) => i)..shuffle(rng);
          final positions = List<int>.filled(items.length, 0);
          for (int rank = 0; rank < indices.length; rank++) {
            positions[indices[rank]] = rank;
          }
          for (int i = 0; i < items.length; i++) {
            candidate.add(items.length > 1 ? positions[i] / (items.length - 1) : 0.0);
          }

        case null:
          candidate.add(0.0);
      }
    }

    return candidate;
  }

  // ── Acquisition function ───────────────────────────────────────────────────

  /// Expected Improvement: EI(x) = (μ − f⋆ − ξ)·Φ(Z) + σ·φ(Z)
  static double _expectedImprovement(double mean, double stdDev, double fBest) {
    if (stdDev <= 0) return 0.0;
    final improvement = mean - fBest - _xi;
    final Z = improvement / stdDev;
    return improvement * _normalCDF(Z) + stdDev * _normalPDF(Z);
  }

  // ── Normal distribution helpers ────────────────────────────────────────────

  static double _normalPDF(double x) =>
      math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi);

  /// Standard normal CDF via Abramowitz & Stegun 26.2.17 (|ε| < 7.5×10⁻⁸).
  static double _normalCDF(double x) {
    if (x <= -8.0) return 0.0;
    if (x >= 8.0) return 1.0;
    const p = 0.2316419;
    const b1 = 0.319381530;
    const b2 = -0.356563782;
    const b3 = 1.781477937;
    const b4 = -1.821255978;
    const b5 = 1.330274429;
    final t = 1.0 / (1.0 + p * x.abs());
    final t2 = t * t;
    final t3 = t2 * t;
    final t4 = t3 * t;
    final t5 = t4 * t;
    final poly = b1 * t + b2 * t2 + b3 * t3 + b4 * t4 + b5 * t5;
    final result = 1.0 - _normalPDF(x.abs()) * poly;
    return x >= 0 ? result : 1.0 - result;
  }
}

// ── Gaussian Process ─────────────────────────────────────────────────────────

/// Gaussian Process regressor with a squared-exponential (RBF) kernel.
///
/// Posterior inference is done via Cholesky decomposition of the kernel matrix
/// for numerical stability.
class _GaussianProcess {
  final double lengthScale;
  final double signalVariance;
  final double noise;

  late List<List<double>> _X;
  late List<double> _alpha; // (K + σ²I)⁻¹ y
  late List<List<double>> _L; // Cholesky factor L where K + σ²I = L Lᵀ

  _GaussianProcess({
    required this.lengthScale,
    required this.signalVariance,
    required this.noise,
  });

  // ── Kernel ──────────────────────────────────────────────────────────────

  double _k(List<double> a, List<double> b) {
    var sqDist = 0.0;
    for (int i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      sqDist += d * d;
    }
    return signalVariance * math.exp(-sqDist / (2.0 * lengthScale * lengthScale));
  }

  // ── Training ─────────────────────────────────────────────────────────────

  void fit(List<List<double>> X, List<double> y) {
    _X = X;
    final n = X.length;

    // Build K + noise·I
    final K = List.generate(
      n,
      (i) => List.generate(n, (j) {
        final kij = _k(X[i], X[j]);
        return i == j ? kij + noise : kij;
      }),
    );

    _L = _cholesky(K);

    // alpha = (K + noise·I)⁻¹ y  via two triangular solves
    _alpha = _backSolve(_L, _forwardSolve(_L, y));
  }

  // ── Prediction ───────────────────────────────────────────────────────────

  ({double mean, double stdDev}) predict(List<double> xStar) {
    final n = _X.length;
    final kStar = List<double>.generate(n, (i) => _k(xStar, _X[i]));

    // Posterior mean: kᵀ α
    double mean = 0.0;
    for (int i = 0; i < n; i++) {
      mean += kStar[i] * _alpha[i];
    }

    // Posterior variance: k(x*, x*) − vᵀv   where v = L⁻¹ k*
    final v = _forwardSolve(_L, kStar);
    var variance = _k(xStar, xStar);
    for (final vi in v) {
      variance -= vi * vi;
    }
    variance = math.max(variance, 1e-10); // numerical floor

    return (mean: mean, stdDev: math.sqrt(variance));
  }
}

// ── Linear-algebra helpers ────────────────────────────────────────────────────

/// Cholesky decomposition: returns lower-triangular L such that A = L Lᵀ.
/// [A] must be symmetric positive (semi-)definite.
List<List<double>> _cholesky(List<List<double>> A) {
  final n = A.length;
  final L = List.generate(n, (_) => List<double>.filled(n, 0.0));

  for (int i = 0; i < n; i++) {
    for (int j = 0; j <= i; j++) {
      double sum = A[i][j];
      for (int k = 0; k < j; k++) {
        sum -= L[i][k] * L[j][k];
      }
      L[i][j] = i == j ? math.sqrt(math.max(sum, 1e-12)) : sum / L[j][j];
    }
  }
  return L;
}

/// Forward substitution: solves L x = b for x (L is lower-triangular).
List<double> _forwardSolve(List<List<double>> L, List<double> b) {
  final n = b.length;
  final x = List<double>.filled(n, 0.0);
  for (int i = 0; i < n; i++) {
    double sum = b[i];
    for (int j = 0; j < i; j++) {
      sum -= L[i][j] * x[j];
    }
    x[i] = sum / L[i][i];
  }
  return x;
}

/// Backward substitution: solves Lᵀ x = b for x (L is lower-triangular).
List<double> _backSolve(List<List<double>> L, List<double> b) {
  final n = b.length;
  final x = List<double>.filled(n, 0.0);
  for (int i = n - 1; i >= 0; i--) {
    double sum = b[i];
    for (int j = i + 1; j < n; j++) {
      sum -= L[j][i] * x[j]; // Lᵀ[i][j] = L[j][i]
    }
    x[i] = sum / L[i][i];
  }
  return x;
}
