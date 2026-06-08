/// Timestamp formatting for the "Quiet Instrument" system.
///
/// Source: `design_app/screens.jsx` `relTime` / `absStamp`. A single place to
/// render the two time voices the design uses — a coarse "x ago" relative
/// string and an absolute "Jun 7 · 3:42 PM" stamp. Inputs are seconds since the
/// Unix epoch (the schema's `createdAt` / `completedAt`). The run-history card
/// carries private copies of these; prefer this ion for new code.
class MixMaxTimeFormat {
  const MixMaxTimeFormat._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Coarse "x ago" relative time. Null renders as an empty string.
  static String relative(int? sec) {
    if (sec == null) return '';
    final d = DateTime.now().millisecondsSinceEpoch / 1000 - sec;
    if (d < 90) return 'just now';
    if (d < 3600) return '${(d / 60).floor()} min ago';
    if (d < 86400) {
      final h = (d / 3600).floor();
      return '$h hr${h > 1 ? 's' : ''} ago';
    }
    final days = (d / 86400).round();
    if (days < 7) return '$days day${days > 1 ? 's' : ''} ago';
    if (days < 28) {
      final w = (days / 7).round();
      return '$w week${w > 1 ? 's' : ''} ago';
    }
    final mo = (days / 30).round();
    return '$mo month${mo > 1 ? 's' : ''} ago';
  }

  /// Absolute "Jun 7 · 3:42 PM" stamp. Null renders as an empty string.
  static String stamp(int? sec) {
    if (sec == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    var hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${_months[dt.month - 1]} ${dt.day} · $hour:$minute $ampm';
  }
}
