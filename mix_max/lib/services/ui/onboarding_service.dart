import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the one-time onboarding tour has already been shown.
///
/// The tour is a first-launch experience only (no replay), so a single local
/// flag is enough — it lives in [SharedPreferences] rather than on the user's
/// Firestore record so it survives before sign-in resolves and never needs a
/// network round-trip to read.
class OnboardingService {
  static const String _seenKey = 'seen_onboarding_v1';

  /// True when the tour has never been shown on this install — i.e. a brand-new
  /// user who should be walked through the app once.
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_seenKey) ?? false);
  }

  /// Marks the tour as seen so it never auto-starts again. Called the moment the
  /// tour begins, so backgrounding the app mid-tour still counts as "shown".
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
