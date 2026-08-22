import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/mock_data.dart';
import '../../models/access_need.dart';
import '../localization/locale.dart';

enum AppRole { passenger, volunteer }

enum SosStage { hidden, confirm, holding, activated }

/// App-wide state that the design's single `Component.state` object held:
/// current role, language, accessibility selections, journey-sharing/report
/// picks, and SOS hold progress. Screen-only local state (e.g. text field
/// contents) stays in each screen's widget instead.
class AppState extends ChangeNotifier {
  AppRole role = AppRole.passenger;
  AppLocale locale = AppLocale.en;

  List<AccessNeed> accessNeeds = List.of(defaultAccessNeeds);
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
