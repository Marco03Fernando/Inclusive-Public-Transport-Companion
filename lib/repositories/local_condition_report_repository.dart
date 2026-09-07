import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/condition_report.dart';
import 'condition_report_repository.dart';

/// On-device implementation of [ConditionReportRepository], storing all
/// reports as a single JSON-encoded list under one SharedPreferences key.
///
/// This is what the app uses today so Condition Reporting works fully
/// offline. When a backend is ready, construct
/// `ConditionReportService(repository: RemoteConditionReportRepository(...))`
/// instead in `main.dart` — nothing else needs to change.
class LocalConditionReportRepository implements ConditionReportRepository {
  static const _storageKey = 'condition_reports';

  @override
  Future<List<ConditionReport>> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final reports = decoded
        .map((e) => ConditionReport.fromJson(e as Map<String, dynamic>))
        .toList();
    reports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return reports;
  }

  @override
  Future<ConditionReport> create(ConditionReport report) async {
    final reports = await fetchAll();
    reports.insert(0, report);
    await _persist(reports);
    return report;
  }

  @override
  Future<ConditionReport> updateStatus({
    required String reportId,
    required ReportStatus status,
    AdminVerification? adminVerification,
  }) async {
    final reports = await fetchAll();
    final index = reports.indexWhere((r) => r.id == reportId);
    if (index == -1) {
      throw StateError('Report $reportId was not found locally.');
    }

    final updated = reports[index].copyWith(
      status: status,
      adminVerification: adminVerification,
    );
    reports[index] = updated;
    await _persist(reports);
    return updated;
  }

  @override
  Future<void> delete(String reportId) async {
    final reports = await fetchAll();
    reports.removeWhere((r) => r.id == reportId);
    await _persist(reports);
  }

  Future<void> _persist(List<ConditionReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(reports.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
