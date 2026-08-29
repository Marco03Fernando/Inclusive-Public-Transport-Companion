import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_data.dart';
import '../../models/access_need.dart';
import '../localization/locale.dart';

const _themeModePrefKey = 'themeMode';

enum AppRole { passenger, volunteer }

enum SosStage { hidden, confirm, holding, activated }

/// App-wide state that the design's single `Component.state` object held:
/// current role, language, accessibility selections, journey-sharing/report
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
  String reportTargetId = 'bus';
  String reportTypeId = 'crowded';
  bool autoShare = false;

  SosStage sosStage = SosStage.hidden;
  double holdPct = 0;
  Timer? _holdTimer;

  int elapsedSec = 97;
  Timer? _elapsedTimer;

  AppState() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSec++;
      notifyListeners();
    });
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModePrefKey);
    for (final mode in ThemeMode.values) {
      if (mode.name == saved) {
        themeMode = mode;
        notifyListeners();
        break;
      }
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

  void setReportTarget(String id) {
    reportTargetId = id;
    notifyListeners();
  }

  void setReportType(String id) {
    reportTypeId = id;
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
    super.dispose();
  }
}
