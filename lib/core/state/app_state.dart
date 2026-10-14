import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_data.dart';
import '../../models/access_need.dart';
import '../localization/locale.dart';

const _themeModePrefKey = 'themeMode';

/// Mirrors `users/{uid}.role` 1:1 via [name]. Passenger/volunteer are
/// chosen at sign-up; [admin] is only ever set by hand in the Firebase
/// console — the Firestore rules stop anyone from giving themselves a role.
enum AppRole {
  passenger,
  volunteer,
  admin;

  /// Anything other than exactly "admin"/"volunteer" (including the legacy
  /// "user" value and a missing field) is a passenger, so a missing or
  /// mistyped role can never grant admin access.
  static AppRole fromName(Object? value) => switch (value) {
    'admin' => AppRole.admin,
    'volunteer' => AppRole.volunteer,
    _ => AppRole.passenger,
  };
}

enum SosStage { hidden, confirm, holding, activated }

/// App-wide state that the design's single `Component.state` object held:
/// current role, language, accessibility selections, journey-sharing
/// picks, and SOS hold progress. Screen-only local state (e.g. text field
/// contents) stays in each screen's widget instead.
class AppState extends ChangeNotifier {
  AppRole role = AppRole.passenger;
  AppLocale locale = AppLocale.en;

  // Defaults to the system setting until the persisted choice (if any)
  // loads; always user-overridable from the profile screen from then on.
  ThemeMode themeMode = ThemeMode.system;

  List<AccessNeed> accessNeeds = List.of(defaultAccessNeeds);

  // Signup-wizard draft — each step's route replaces the last, so these
  // survive on AppState (same pattern as accessNeeds) until the final
  // "Finish setup" step creates the Firebase account.
  String signupName = '';
  String signupPhone = '';
  String signupDob = '';
  String signupEmail = '';
  String signupPassword = '';

  Set<String> planFilterIds = {'wheelchair'};
  bool autoShare = false;

  SosStage sosStage = SosStage.hidden;
  double holdPct = 0;
  Timer? _holdTimer;

  /// Journey-sharing elapsed seconds. Ticks on its own notifier so the
  /// once-a-second update only rebuilds the label that shows it, not every
  /// widget (and the whole MaterialApp) listening to [AppState].
  final ValueNotifier<int> elapsed = ValueNotifier<int>(97);
  Timer? _elapsedTimer;

  int get elapsedSec => elapsed.value;

  /// Completes once the saved theme mode has been applied. `AuthGate`
  /// waits for it so the first real screen never flashes the wrong theme.
  late final Future<void> ready;

  AppState() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value++;
    });
    ready = _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModePrefKey);
      for (final mode in ThemeMode.values) {
        if (mode.name == saved) {
          themeMode = mode;
          notifyListeners();
          break;
        }
      }
    } catch (e) {
      // Keeps following the system theme.
      if (kDebugMode) debugPrint('[AppState] theme mode load failed: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePrefKey, mode.name);
  }

  String get elapsedLabel {
    final m = (elapsedSec ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void setRole(AppRole value) {
    role = value;
    notifyListeners();
  }

  void setLocale(AppLocale value) {
    locale = value;
    notifyListeners();
  }

  void toggleLocale() {
    locale = locale == AppLocale.en ? AppLocale.si : AppLocale.en;
    notifyListeners();
  }

  void toggleAccessNeed(String id) {
    accessNeeds = accessNeeds
        .map((n) => n.id == id ? n.copyWith(checked: !n.checked) : n)
        .toList();
    notifyListeners();
  }

  void setAccessNeeds(List<AccessNeed> value) {
    accessNeeds = value;
    notifyListeners();
  }

  void setSignupBasic({
    required String name,
    required String phone,
    required String dob,
    required String email,
    required String password,
  }) {
    signupName = name;
    signupPhone = phone;
    signupDob = dob;
    signupEmail = email;
    signupPassword = password;
    notifyListeners();
  }

  void togglePlanFilter(String id) {
    if (!planFilterIds.remove(id)) planFilterIds.add(id);
    notifyListeners();
  }

  void toggleAutoShare() {
    autoShare = !autoShare;
    notifyListeners();
  }

  void openSosConfirm() {
    sosStage = SosStage.confirm;
    holdPct = 0;
    notifyListeners();
  }

  void closeSos() {
    _holdTimer?.cancel();
    sosStage = SosStage.hidden;
    holdPct = 0;
    notifyListeners();
  }

  /// Fills over 3 seconds (30 ticks x 100ms), matching the design's timer.
  void startHold() {
    _holdTimer?.cancel();
    sosStage = SosStage.holding;
    notifyListeners();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      holdPct = (holdPct + 100 / 30).clamp(0, 100);
      if (holdPct >= 100) {
        timer.cancel();
        sosStage = SosStage.activated;
      }
      notifyListeners();
    });
  }

  void cancelHold() {
    if (sosStage == SosStage.holding) {
      _holdTimer?.cancel();
      sosStage = SosStage.confirm;
      holdPct = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _elapsedTimer?.cancel();
    elapsed.dispose();
    super.dispose();
  }
}
