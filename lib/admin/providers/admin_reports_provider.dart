import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/condition_report.dart';
import '../../models/report_filters.dart';
import '../models/admin_exception.dart';
import '../models/report_filter.dart';
import '../models/report_stats.dart';
import '../repositories/admin_report_repository.dart';
import '../services/admin_report_service.dart';

/// State for the admin dashboard, report list, and report details.
///
/// Holds ONE live subscription to all reports. Everything else — the
/// dashboard counts, the filtered list, the details screen — is derived
/// from that single list, so they can never disagree with each other.
///
/// The subscription only runs while an admin session is active:
/// `app.dart` wires this through a `ChangeNotifierProxyProvider`
/// that calls [syncSession] whenever `AdminAuthProvider` changes.
class AdminReportsProvider extends ChangeNotifier {
  final AdminReportService _service;

  AdminReportsProvider({required this._service});

  StreamSubscription<AdminReportsSnapshot>? _subscription;
  bool _disposed = false;

  List<ConditionReport> _reports = const [];
  int _skipped = 0;
  ReportFilter _filter = ReportFilter.all;
  SubjectFilter _subject = SubjectFilter.all;
  TypeFilter _type = TypeFilter.all;
  ReportSort _sort = ReportSort.newestFirst;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;
  String? _actionError;

  /// Every report, newest first.
  List<ConditionReport> get allReports => _reports;

  /// The active status + subject + type filters and ordering.
  ReportQuery get query => ReportQuery(
    status: _filter.statusFilter,
    subject: _subject,
    type: _type,
    sort: _sort,
  );

  /// Reports matching every selected filter, in the selected order.
  List<ConditionReport> get reports => List.unmodifiable(query.apply(_reports));

  ReportFilter get filter => _filter;
  SubjectFilter get subjectFilter => _subject;
  TypeFilter get typeFilter => _type;
  ReportSort get sort => _sort;

  /// True when subject or type narrow the list (status tabs aside).
  bool get hasExtraFilters =>
      _subject != SubjectFilter.all || _type != TypeFilter.all;

  /// Overall counts across every report (dashboard tiles).
  ReportStats get stats => ReportStats.fromReports(_reports);

  /// Counts within the selected subject + type, i.e. how many reports
  /// each status tab would show right now.
  ReportStats get scopedStats => ReportStats.fromReports(
    _reports
        .where(ReportQuery(subject: _subject, type: _type).matches)
        .toList(),
  );

  /// How many `condition_reports` documents couldn't be read.
  int get skippedCount => _skipped;

  /// True until the first snapshot arrives.
  bool get isLoading => _isLoading;

  /// True while an accept/reject/comment/delete is being saved.
  bool get isUpdating => _isUpdating;

  /// Set when loading the reports failed (permission vs network wording
  /// comes from the repository).
  String? get error => _error;

  /// Message from the last failed accept/reject/comment/delete.
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

  void setSubjectFilter(SubjectFilter value) {
    if (_subject == value) return;
    _subject = value;
    notifyListeners();
  }

  void setTypeFilter(TypeFilter value) {
    if (_type == value) return;
    _type = value;
    notifyListeners();
  }

  void setSort(ReportSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  /// Back to every report, newest first.
  void clearFilters() {
    _filter = ReportFilter.all;
    _subject = SubjectFilter.all;
    _type = TypeFilter.all;
    _sort = ReportSort.newestFirst;
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
      (snapshot) {
        _reports = snapshot.reports;
        _skipped = snapshot.skipped;
        _isLoading = false;
        _error = null;
        _notify();
      },
      onError: (Object e) {
        _isLoading = false;
        _error = e is AdminException
            ? e.message
            : 'Could not load reports. Please check your connection '
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
    _skipped = 0;
    _filter = ReportFilter.all;
    _subject = SubjectFilter.all;
    _type = TypeFilter.all;
    _sort = ReportSort.newestFirst;
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

  /// Accepts [report] (also used to change a rejected report to accepted).
  /// Returns true on success; on failure [actionError] is set.
  Future<bool> acceptReport(ConditionReport report, {String? comment}) {
    return _run(
      () => _service.acceptReport(
        reportId: report.id,
        currentStatus: report.status,
        comment: comment,
      ),
    );
  }

  /// Rejects [report] with a mandatory [reason].
  Future<bool> rejectReport(ConditionReport report, String reason) {
    return _run(
      () => _service.rejectReport(
        reportId: report.id,
        currentStatus: report.status,
        reason: reason,
      ),
    );
  }

  /// Adds or edits the admin comment without changing the status.
  Future<bool> updateComment(String reportId, String comment) {
    return _run(
      () => _service.updateComment(reportId: reportId, comment: comment),
      fallbackError: 'Could not save the comment. Please try again.',
    );
  }

  /// Live "is this report shown in Community Reports?" for the details
  /// screen.
  Stream<bool> watchPublished(String reportId) =>
      _service.watchPublished(reportId);

  /// Takes a report out of Community Reports, or puts it back.
  Future<bool> setPublished(String reportId, {required bool publish}) {
    return _run(
      () => _service.setPublished(reportId: reportId, publish: publish),
      fallbackError: 'Could not change community sharing. Please try again.',
    );
  }

  /// Permanently deletes a report (and its photo). The live subscription
  /// then drops it from every list and count by itself.
  Future<bool> deleteReport(String reportId) {
    return _run(
      () => _service.deleteReport(reportId),
      fallbackError: 'Could not delete the report. Please try again.',
    );
  }

  Future<bool> _run(
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
    } catch (e) {
      if (kDebugMode) debugPrint('[Admin] Unexpected update failure: $e');
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
