import 'package:flutter/foundation.dart';

import '../models/condition_report.dart';
import '../services/auth_service.dart';
import '../services/condition_report_service.dart';

/// App-wide state for the current user's submitted condition reports.
///
/// Sits on top of [ConditionReportService] (business logic) and
/// [AuthService] (who "the current user" is). Screens only ever call
/// [loadReports], [submitReport], and [deleteReport] and read [reports] /
/// [isLoading] / [error] — they never touch Firebase directly, matching
/// the Screen → Provider → Service → Repository → Firebase layering.
class ReportsProvider extends ChangeNotifier {
  final ConditionReportService _service;
  final AuthService _authService;

  ReportsProvider({
    required ConditionReportService service,
    required AuthService authService,
  })  : _service = service,
        _authService = authService;

  List<ConditionReport> _reports = [];
  bool _isLoading = false;
  String? _error;

  /// Newest-first list of the current user's reports.
  List<ConditionReport> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads the signed-in user's reports. Call once, e.g. right when
  /// "My Reports" appears — signs the device in (anonymously, if it
  /// hasn't been already) before querying Firestore.
  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final userId = await _authService.ensureSignedIn();
      _reports = await _service.getUserReports(userId);
    } catch (_) {
      _error = 'Could not load your reports. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits a new report and adds it to the in-memory list on success.
  /// Attaches the signed-in user's ID before it reaches the service —
  /// screens build a [ConditionReport] via `ConditionReport.fromDraft`
  /// without needing to know about auth at all.
  ///
  /// Returns true on success; on failure, [error] is set with a
  /// user-facing message and this returns false.
Future<bool> submitReport(ConditionReport report) async {
  _error = null;

  try {
    print("===== PROVIDER SUBMIT START =====");

    final userId = await _authService.ensureSignedIn();

    print("Firebase User ID: $userId");

    final saved = await _service.createReport(
      report.copyWith(userId: userId),
    );

    print("REPORT SAVED FROM SERVICE");

    _reports = [saved, ..._reports];

    notifyListeners();
    return true;

  } catch (e, stackTrace) {

    print("🔥 PROVIDER ERROR:");
    print(e);
    print(stackTrace);

    _error = e.toString();

    notifyListeners();

    return false;
  }
}

  /// Deletes a report (e.g. the user retracts a mistaken report) and
  /// removes it from the in-memory list on success.
  Future<bool> deleteReport(String reportId) async {
    _error = null;
    try {
      await _service.deleteReport(reportId);
      _reports = _reports.where((r) => r.id != reportId).toList();
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Could not delete that report. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
