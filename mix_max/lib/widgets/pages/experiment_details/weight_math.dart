import 'package:flutter/material.dart';

/// Outcome-weighting helpers shared by the Priorities section and the
/// experiment-details page (which normalises weights when a run is launched).
///
/// Source: `design_app/screens.jsx` — `WEIGHT_COLORS`, `weightAlpha`,
/// `normalizeWeightList`.

/// Muted, warm-leaning slice palette for the weight donut and sliders. Shares
/// the app's chroma/lightness so the priorities card sits beside the rest of
/// the design. Outcomes index into it by position, wrapping past the end.
const List<Color> kWeightColors = [
  Color(0xFF7E719A),
  Color(0xFFB5872B),
  Color(0xFF6E8A63),
  Color(0xFFB0715B),
  Color(0xFF5E8A86),
  Color(0xFF9A6A8C),
  Color(0xFF8A7A3E),
];

/// The slice colour for the outcome at [index], wrapping around the palette.
Color weightColorAt(int index) =>
    kWeightColors[index % kWeightColors.length];

/// Rescales [weights] so they sum to exactly 100 while preserving their
/// proportions. An already-balanced list passes through unchanged; an all-zero
/// list splits the budget evenly. Rounding drift is corrected by nudging the
/// largest slices first so the proportions stay as faithful as possible.
///
/// Source: `design_app/screens.jsx` `normalizeWeightList`.
List<double> normalizeWeightList(List<double> weights) {
  final n = weights.length;
  if (n == 0) return List<double>.from(weights);

  final sum = weights.fold<double>(0.0, (a, b) => a + b);
  if (sum == 100) return List<double>.from(weights);

  final List<int> scaled;
  if (sum == 0) {
    final base = (100 / n).floor();
    scaled = List<int>.filled(n, base);
  } else {
    scaled = weights.map((w) => (w / sum * 100).round()).toList();
  }

  // Correct rounding drift so the total lands on exactly 100, nudging the
  // largest original slices first.
  var drift = 100 - scaled.fold<int>(0, (a, b) => a + b);
  final order = List<int>.generate(n, (i) => i)
    ..sort((a, b) => weights[b].compareTo(weights[a]));
  var i = 0;
  var guard = 0;
  while (drift != 0 && guard < 10000) {
    final idx = order[i % n];
    if (drift > 0) {
      scaled[idx] += 1;
      drift -= 1;
    } else if (scaled[idx] > 0) {
      scaled[idx] -= 1;
      drift += 1;
    }
    i++;
    guard++;
  }

  return scaled.map((v) => v.toDouble()).toList();
}
