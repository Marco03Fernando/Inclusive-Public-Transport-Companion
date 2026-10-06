import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/condition_report.dart';
import '../models/admin_exception.dart';
import '../models/report_filter.dart';
import '../models/report_stats.dart';
import '../services/admin_report_service.dart';

/// State for the admin dashboard, report list, and report details.
///
/// Holds ONE live subscription to all reports. Everything else — the
/// dashboard counts, the filtered list, the details screen — is derived
/// from that single list, so they can never disagree with each other.
///
/// The subscription only runs while an admin session is active:
/// `main.dart` wires this through a `ChangeNotifierProxyProvider`
/// that calls [syncSession] whenever `AdminAuthProvider` changes.
class AdminReportsProvider extends ChangeNotifier {
  final AdminReportService _service;

  AdminReportsProvider({required AdminReportService service})
      : _service = service;

  StreamSubscription<List<ConditionReport>>? _subscription;
  bool _disposed = false;

  List<ConditionReport> _reports = const [];
  ReportFilter _filter = ReportFilter.all;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;
  String? _actionError;

  /// Every report, newest first.
  List<ConditionReport> get allReports => _reports;

  /// Reports matching the selected status tab.
  List<ConditionReport> get reports =>
      _reports.where(_filter.matches).toList(growable: false);

  ReportFilter get filter => _filter;
  ReportStats get stats => ReportStats.fromReports(_reports);

  /// True until the first snapshot arrives.
  bool get isLoading => _isLoading;

  /// True while an accept/reject is being saved.
  bool get isUpdating => _isUpdating;

  /// Set when loading the reports failed.
  String? get error => _error;

  /// Message from the last failed accept/reject.
  String? get actionError => _actionError;

  ConditionReport? reportById(String id) {
    for (final report in _reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  void setFilter(ReportFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  /// Starts or stops the live subscription to match the admin session.
  /// Called from `ChangeNotifierProxyProvider.update`, i.e. DURING a
  /// build — so it must not call [notifyListeners] synchronously.
  void syncSession({required bool isAdmin}) {
    if (isAdmin) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (_subscription != null) return;

    _isLoading = true;
    _error = null;

    _subscription = _service.watchAllReports().listen(
      (reports) {
        _reports = reports;
        _isLoading = false;
        _error = null;
        _notify();
      },
      onError: (Object _) {
        _isLoading = false;
        _error = 'Could not load reports. Please check your connection '
            'and admin permissions, then try again.';
        _notify();
      },
    );
  }

  void _stop() {
    if (_subscription == null && _reports.isEmpty) return;

    _subscription?.cancel();
    _subscription = null;
    _reports = const [];
    _filter = ReportFilter.all;
    _isLoading = false;
    _isUpdating = false;
    _error = null;
    _actionError = null;

    // We're inside a build (see syncSession) — notify after it finishes.
    scheduleMicrotask(_notify);
  }

  /// Re-subscribes after a load error.
  void retry() {
    _subscription?.cancel();
    _subscription = null;
    _start();
    notifyListeners();
  }

  /// Accepts a report. Returns true on success; on failure [actionError]
  /// is set and this returns false.
  Future<bool> acceptReport(String reportId, {String? comment}) {
    return _review(
      () => _service.acceptReport(reportId: reportId, comment: comment),
    );
  }

  /// Rejects a report with a mandatory [reason].
  Future<bool> rejectReport(String reportId, String reason) {
    return _review(
      () => _service.rejectReport(reportId: reportId, reason: reason),
    );
  }

  /// Permanently deletes a report (and its photo). The live subscription
  /// then drops it from every list and count by itself.
  Future<bool> deleteReport(String reportId) {
    return _review(
      () => _service.deleteReport(reportId),
      fallbackError: 'Could not delete the report. Please try again.',
    );
  }

  Future<bool> _review(
    Future<void> Function() action, {
    String fallbackError = 'Could not update the report. Please try again.',
  }) async {
    _isUpdating = true;
    _actionError = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on AdminException catch (e) {
      _actionError = e.message;
      return false;
    } catch (_) {
      _actionError = fallbackError;
      return false;
    } finally {
      _isUpdating = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
