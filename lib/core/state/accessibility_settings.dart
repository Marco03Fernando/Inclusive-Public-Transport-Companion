import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _textSizePrefKey = 'a11y.textSize';
const _highContrastPrefKey = 'a11y.highContrast';
const _readAloudPrefKey = 'a11y.readAloud';
const _speechRatePrefKey = 'a11y.speechRate';

/// In-app text size presets, on top of (never below) the OS text size.
enum TextSizePreset {
  standard(1.0, 'textSizeStandard'),
  large(1.25, 'textSizeLarge'),
  extraLarge(1.5, 'textSizeExtraLarge');

  const TextSizePreset(this.scale, this.labelKey);

  final double scale;

  /// `context.t` key for the settings label.
  final String labelKey;

  int get percent => (scale * 100).round();
}

/// Read Aloud speaking speed. Values are `flutter_tts` rates, where 0.5 is
/// the engine's normal speed on both Android and iOS.
enum SpeechRate {
  slow(0.38, 'speechSlow'),
  normal(0.5, 'speechNormal'),
  fast(0.6, 'speechFast');

  const SpeechRate(this.rate, this.labelKey);

  final double rate;
  final String labelKey;
}

/// The user's accessibility preferences — one place for the whole app.
///
/// Kept separate from [AppState] so changing text size or contrast only
/// rebuilds what depends on it. Persisted on the device with
/// SharedPreferences (same mechanism as the theme mode); these are
/// per-device display preferences, so nothing is written to Firestore.
class AccessibilitySettings extends ChangeNotifier {
  AccessibilitySettings() {
    ready = _load();
  }

  /// Completes once the saved preferences have been applied (never throws).
  /// `AuthGate` waits for it so the first real screen opens at the user's
  /// text size / contrast instead of re-laying out a moment later.
  late final Future<void> ready;

  TextSizePreset _textSize = TextSizePreset.standard;
  bool _highContrast = false;
  bool _readAloudEnabled = true;
  SpeechRate _speechRate = SpeechRate.normal;

  TextSizePreset get textSize => _textSize;
  bool get highContrast => _highContrast;

  /// Whether the "Read aloud" buttons are shown on screens.
  bool get readAloudEnabled => _readAloudEnabled;
  SpeechRate get speechRate => _speechRate;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _textSize = _byName(
        TextSizePreset.values,
        prefs.getString(_textSizePrefKey),
        TextSizePreset.standard,
      );
      _speechRate = _byName(
        SpeechRate.values,
        prefs.getString(_speechRatePrefKey),
        SpeechRate.normal,
      );
      _highContrast = prefs.getBool(_highContrastPrefKey) ?? false;
      _readAloudEnabled = prefs.getBool(_readAloudPrefKey) ?? true;
      notifyListeners();
    } catch (e) {
      // Defaults stay in place; the app is fully usable without them.
      if (kDebugMode) debugPrint('[Accessibility] load failed: $e');
    }
  }

  Future<void> setTextSize(TextSizePreset value) async {
    if (_textSize == value) return;
    _textSize = value;
    notifyListeners();
    await _save((p) => p.setString(_textSizePrefKey, value.name));
  }

  Future<void> setHighContrast(bool value) async {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
    await _save((p) => p.setBool(_highContrastPrefKey, value));
  }

  Future<void> setReadAloudEnabled(bool value) async {
    if (_readAloudEnabled == value) return;
    _readAloudEnabled = value;
    notifyListeners();
    await _save((p) => p.setBool(_readAloudPrefKey, value));
  }

  Future<void> setSpeechRate(SpeechRate value) async {
    if (_speechRate == value) return;
    _speechRate = value;
    notifyListeners();
    await _save((p) => p.setString(_speechRatePrefKey, value.name));
  }

  /// The [TextScaler] to install app-wide given the OS [system] scaler.
  TextScaler textScalerFor(TextScaler system) =>
      PreferredTextScaler(system: system, minimumScale: _textSize.scale);

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (e) {
      if (kDebugMode) debugPrint('[Accessibility] save failed: $e');
    }
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

/// Scales every font size by whichever is LARGER: the operating system's
/// text size ([system], including Android 14's non-linear scaling) or the
/// in-app preset ([minimumScale]).
///
/// So the in-app preset can only ever make text bigger: a user with a large
/// system font who picks "Standard" keeps their system size, and a user
/// with the default system font who picks "Extra Large" gets 150%. The two
/// are deliberately not multiplied, which would make text far larger than
/// either setting asked for.
@immutable
class PreferredTextScaler extends TextScaler {
  const PreferredTextScaler({required this.system, required this.minimumScale});

  final TextScaler system;
  final double minimumScale;

  @override
  double scale(double fontSize) =>
      math.max(system.scale(fontSize), fontSize * minimumScale);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor =>
      // ignore: deprecated_member_use
      math.max(system.textScaleFactor, minimumScale);

  @override
  bool operator ==(Object other) =>
      other is PreferredTextScaler &&
      other.system == system &&
      other.minimumScale == minimumScale;

  @override
  int get hashCode => Object.hash(system, minimumScale);
}
