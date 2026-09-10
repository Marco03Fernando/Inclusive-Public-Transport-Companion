import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/condition_report.dart';
import 'condition_report_repository.dart';

/// On-device implementation of [ConditionReportRepository], storing all
/// reports as a single JSON-encoded list under one SharedPreferences key.
///
/// No longer the default (see `main.dart`, which now injects
/// [FirebaseConditionReportRepository]) — kept around for offline
/// development/testing, or as an emergency fallback.
class LocalConditionReportRepository implements ConditionReportRepository {
  static const _storageKey = 'condition_reports';

  Future<List<ConditionReport>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final reports = decoded
        .map((e) => ConditionReport.fromJson(e as Map<String, dynamic>))
        .toList();
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  @override
  Future<ConditionReport> createReport(ConditionReport report) async {
    final reports = await _readAll();
    final withId = report.id.isEmpty
        ? report.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString())
        : report;
    reports.insert(0, withId);
    await _persist(reports);
    return withId;
  }

  @override
  Future<List<ConditionReport>> getUserReports(String userId) async {
    final reports = await _readAll();
    return reports.where((r) => r.userId == userId).toList();
  }

  @override
  Future<ConditionReport> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminComment,
  }) async {
    final reports = await _readAll();
    final index = reports.indexWhere((r) => r.id == reportId);
    if (index == -1) {
      throw StateError('Report $reportId was not found locally.');
    }

    final updated = reports[index].copyWith(
      status: status,
      adminComment: adminComment,
      updatedAt: DateTime.now(),
    );
    reports[index] = updated;
    await _persist(reports);
    return updated;
  }

  @override
  Future<void> deleteReport(String reportId) async {
    final reports = await _readAll();
    reports.removeWhere((r) => r.id == reportId);
    await _persist(reports);
  }

  Future<void> _persist(List<ConditionReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(reports.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
