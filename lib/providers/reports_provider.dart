import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/condition_report.dart';
import '../models/report_exception.dart';
import '../services/auth_service.dart';
import '../services/condition_report_service.dart';

/// App-wide state for the current user's submitted condition reports.
///
/// Sits on top of [ConditionReportService] (business logic) and
/// [AuthService] (who "the current user" is). Screens only ever call
/// [loadReports], [submitReport], and [deleteReport] and read [reports] /
/// [isLoading] / [error] / [submitError] — they never touch Firebase
/// directly, matching the Screen → Provider → Service → Repository →
/// Firebase layering.
class ReportsProvider extends ChangeNotifier {
  final ConditionReportService _service;
  final AuthService _authService;

  ReportsProvider({
    required ConditionReportService service,
    required AuthService authService,
  }) : _service = service,
       _authService = authService;

  List<ConditionReport> _reports = [];
  bool _isLoading = false;
  String? _error;
  String? _submitError;
  ReportFailure? _submitFailure;
  String? _sessionUserId;
  StreamSubscription<List<ConditionReport>>? _subscription;

  /// Newest-first list of the current user's reports (live from Firestore).
  List<ConditionReport> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;

  /// Why the "My Reports" list couldn't be loaded, if it couldn't.
  String? get error => _error;

  /// Why the last [submitReport] failed (user-facing), and in which layer.
  String? get submitError => _submitError;
  ReportFailure? get submitFailure => _submitFailure;

  /// Starts or stops the live subscription to match the signed-in user.
  /// Called from `ChangeNotifierProxyProvider.update` in `app.dart`, i.e.
  /// DURING a build — so the actual work is deferred to a microtask.
  void syncSession({required String? userId}) {
    if (userId == _sessionUserId) return;
    _sessionUserId = userId;

    if (userId == null) {
      _subscription?.cancel();
      _subscription = null;
      _reports = [];
      _isLoading = false;
      _error = null;
      _submitError = null;
      _submitFailure = null;
      scheduleMicrotask(notifyListeners);
    } else {
      scheduleMicrotask(loadReports);
    }
  }

  /// (Re)subscribes to the signed-in user's reports. Completes once the
  /// first snapshot (or error) arrives, so it works with pull-to-refresh.
  Future<void> loadReports() async {
    final userId = _authService.currentUserId;
    if (userId == null || userId != _sessionUserId) return;

    await _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    final firstEvent = Completer<void>();
    void settle() {
      if (!firstEvent.isCompleted) firstEvent.complete();
    }

    _subscription = _service
        .watchUserReports(userId)
        .listen(
          (reports) {
            // Signed out (or switched account) since subscribing.
            if (userId != _sessionUserId) return;
            _reports = reports;
            _isLoading = false;
            _error = null;
            notifyListeners();
            settle();
          },
          onError: (Object e) {
            _log('loadReports failed: $e');
            _isLoading = false;
            _error = e is ReportException
                ? e.message
                : 'Could not load your reports. Please try again.';
            notifyListeners();
            settle();
          },
        );
    return firstEvent.future;
  }

  /// Submits a new report. Attaches the signed-in user's ID before it
  /// reaches the service — screens build a [ConditionReport] via
  /// `ConditionReport.fromDraft` without needing to know about auth.
  ///
  /// Returns true on success; on failure, [submitError] /
  /// [submitFailure] say what went wrong and this returns false.
  Future<bool> submitReport(ConditionReport report) async {
    _submitError = null;
    _submitFailure = null;

    try {
      final userId = await _authService.ensureSignedIn();
      final saved = await _service.createReport(
        report.copyWith(userId: userId),
      );
      // The live subscription normally delivers it first; avoid duplicates.
      if (!_reports.any((r) => r.id == saved.id)) {
        _reports = [saved, ..._reports];
      }
      notifyListeners();
      return true;
    } on ReportException catch (e) {
      _log('submitReport failed: $e');
      _submitFailure = e.failure;
      _submitError = e.message;
    } on AuthServiceException catch (e) {
      _log('submitReport failed: [auth] $e');
      _submitFailure = ReportFailure.auth;
      _submitError = e.message;
    } catch (e, stackTrace) {
      _log('submitReport failed: [unknown] $e\n$stackTrace');
      _submitFailure = ReportFailure.unknown;
      _submitError = 'Could not submit your report. Please try again.';
    }
    notifyListeners();
    return false;
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
    } catch (e) {
      _log('deleteReport failed: $e');
      _error = e is ReportException
          ? e.message
          : 'Could not delete that report. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ReportsProvider] $message');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
