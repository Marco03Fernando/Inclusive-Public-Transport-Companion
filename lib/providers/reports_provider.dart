import 'package:flutter/foundation.dart';

import '../models/condition_report.dart';
import '../services/condition_report_service.dart';

/// App-wide state for submitted condition reports, backed by
/// [ConditionReportService]. Screens listen via `Consumer`/`context.watch`
/// without knowing whether reports are coming from local storage, a REST
/// API, or Firestore underneath.
class ReportsProvider extends ChangeNotifier {
  final ConditionReportService _service;

  ReportsProvider({required ConditionReportService service}) : _service = service;

  List<ConditionReport> _reports = [];
  bool _isLoading = false;
  String? _error;

  /// Newest-first list of submitted reports.
  List<ConditionReport> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads all reports. Call once, e.g. right when "My Reports" appears.
  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _service.fetchReports();
    } catch (_) {
      _error = 'Could not load your reports. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits a new report and adds it to the in-memory list on success.
  /// Returns true on success; on failure, [error] is set with a
  /// user-facing message and this returns false.
  Future<bool> submitReport(ConditionReport report) async {
    _error = null;
    try {
      final saved = await _service.submitReport(report);
      _reports = [saved, ..._reports];
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Could not submit your report. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
