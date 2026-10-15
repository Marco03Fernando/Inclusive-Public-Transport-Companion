import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the first-run welcome screens were already shown, so
/// they appear once per install (not after sign-out or on later launches).
class OnboardingPrefs {
  OnboardingPrefs._();

  static const _key = 'welcomeSeen';

  /// True if the welcome screens should be shown. Any storage error means
  /// "don't show", so a broken store can never trap anyone before sign-in.
  static Future<bool> shouldShowWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_key) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> markWelcomeSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {}
  }
}
