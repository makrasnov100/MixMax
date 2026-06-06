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
  /// rounded to that many places first (matching `fmt(v, dp)`). Null or NaN
  /// renders as `—`.
  static String number(double? v, {int? decimals}) {
    if (v == null || v.isNaN) return '—';
    final r = decimals == null ? v : double.parse(v.toStringAsFixed(decimals));
    return r == r.truncateToDouble() ? r.truncate().toString() : r.toString();
  }
}
