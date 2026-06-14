/// Number formatting for the "Quiet Instrument" system.
///
/// Source: `theme.jsx` `fmt`. A single place to render a numeric value the way
/// the design does — drop a trailing `.0`, optionally round to a fixed number
/// of decimals first, and fall back to an em dash for null/NaN. Several widgets
/// were each carrying a private copy of this; prefer this ion for new code.
class MixMaxFormat {
  const MixMaxFormat._();

  /// Format [v] nicely: an integer prints without a decimal point, anything
  /// else keeps its natural decimals. When [decimals] is given the value is
  /// rounded to that many places first (matching `fmt(v, dp)`). When [step] is
  /// given instead, the value is rounded to the precision that step implies —
  /// so a value carrying floating-point noise (e.g. `2.4000000000000004` from
  /// snapping to a `0.1` step) renders cleanly as `2.4`. Null or NaN renders as
  /// `—`.
  static String number(double? v, {int? decimals, double? step}) {
    if (v == null || v.isNaN) return '—';
    final dp = decimals ?? (step != null ? decimalsOf(step) : null);
    final r = dp == null ? v : double.parse(v.toStringAsFixed(dp));
    return r == r.truncateToDouble() ? r.truncate().toString() : r.toString();
  }

  /// Decimal places needed to represent [v] exactly — e.g. `0.25` → 2, `1` → 0.
  /// Used to round a value onto its step without carrying floating-point noise.
  static int decimalsOf(double v) {
    if (v.isNaN || v == v.truncateToDouble()) return 0;
    final s = v.toString();
    final dot = s.indexOf('.');
    return dot < 0 ? 0 : s.length - dot - 1;
  }
}
