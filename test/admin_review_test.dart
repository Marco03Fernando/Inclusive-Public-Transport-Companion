import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/admin/models/admin_exception.dart';
import 'package:colombo_pal/admin/models/report_filter.dart';
import 'package:colombo_pal/admin/models/report_stats.dart';
import 'package:colombo_pal/admin/providers/admin_reports_provider.dart';
import 'package:colombo_pal/admin/repositories/admin_report_repository.dart';
import 'package:colombo_pal/admin/services/admin_report_service.dart';
import 'package:colombo_pal/models/condition_report.dart';

ConditionReport _report(String id, ReportStatus status) => ConditionReport(
  id: id,
  userId: 'user-1',
  subject: ReportSubject.bus,
  vehicleOrStationNumber: 'NB-1234',
  location: const ReportLocation(label: 'Fort'),
  conditionType: ConditionType.brokenRamp,
  description: 'Ramp is bent and will not lower.',
  createdAt: DateTime(2026, 10, 1),
  status: status,
);

/// In-memory stand-in for `FirebaseAdminReportRepository`: applies the same
/// "only status / adminComment / updatedAt" writes and conflict check.
class _FakeRepository implements AdminReportRepository {
  final Map<String, ConditionReport> docs;
  final List<Map<String, Object?>> writes = [];

  _FakeRepository(List<ConditionReport> reports)
    : docs = {for (final r in reports) r.id: r};

  @override
  Stream<AdminReportsSnapshot> watchAllReports() =>
      Stream.value((reports: docs.values.toList(), skipped: 1));

  @override
  Future<void> reviewReport({
    required String reportId,
    required ReportStatus decision,
    required String adminComment,
    required ReportStatus expectedStatus,
  }) async {
    final current = docs[reportId];
    if (current == null) throw const AdminException('gone');
    if (current.status != expectedStatus) {
      throw const AdminException('changed');
    }
    writes.add({'status': decision.name, 'adminComment': adminComment});
    docs[reportId] = current.copyWith(
      status: decision,
      adminComment: adminComment,
    );
  }

  @override
  Future<void> updateComment({
    required String reportId,
    required String adminComment,
  }) async {
    writes.add({'adminComment': adminComment});
    docs[reportId] = docs[reportId]!.copyWith(adminComment: adminComment);
  }

  @override
  Future<void> deleteReport(String reportId) async => docs.remove(reportId);
}

void main() {
  group('status helpers', () {
    test('stored status values parse, unknown stays under review', () {
      expect(parseReportStatus('accepted'), ReportStatus.accepted);
      expect(parseReportStatus('rejected'), ReportStatus.rejected);
      expect(parseReportStatus('verified'), ReportStatus.verified);
      expect(parseReportStatus('underReview'), ReportStatus.underReview);
      expect(parseReportStatus('bogus'), ReportStatus.underReview);
      expect(parseReportStatus(null), ReportStatus.underReview);
    });

    test('dashboard counts total / under review / accepted / rejected', () {
      final stats = ReportStats.fromReports([
        _report('a', ReportStatus.underReview),
        _report('b', ReportStatus.accepted),
        _report('c', ReportStatus.verified), // legacy "verified" = accepted
        _report('d', ReportStatus.rejected),
      ]);
      expect(stats.total, 4);
      expect(stats.pending, 1);
      expect(stats.accepted, 2);
      expect(stats.rejected, 1);
      expect(stats.countFor(ReportFilter.accepted), 2);
    });
  });

  group('admin review', () {
    late _FakeRepository repo;
    late AdminReportsProvider provider;

    setUp(() async {
      repo = _FakeRepository([
        _report('a', ReportStatus.underReview),
        _report('b', ReportStatus.rejected),
      ]);
      provider = AdminReportsProvider(
        service: AdminReportService(repository: repo),
      );
      provider.syncSession(isAdmin: true);
      await Future<void>.delayed(Duration.zero);
    });

    test('live list loads and counts malformed documents', () {
      expect(provider.allReports, hasLength(2));
      expect(provider.skippedCount, 1);
      provider.setFilter(ReportFilter.underReview);
      expect(provider.reports.single.id, 'a');
    });

    test('accept writes status + default comment only', () async {
      final ok = await provider.acceptReport(provider.reportById('a')!);
      expect(ok, isTrue);
      expect(repo.writes.single, {
        'status': 'accepted',
        'adminComment': AdminReportService.defaultAcceptComment,
      });
    });

    test('reject needs a reason', () async {
      final report = provider.reportById('a')!;
      expect(await provider.rejectReport(report, '   '), isFalse);
      expect(provider.actionError, contains('reason'));
      expect(repo.writes, isEmpty);

      expect(await provider.rejectReport(report, 'Duplicate'), isTrue);
      expect(repo.docs['a']!.status, ReportStatus.rejected);
    });

    test('a reviewed report can change decision', () async {
      final ok = await provider.acceptReport(
        provider.reportById('b')!,
        comment: 'Re-checked',
      );
      expect(ok, isTrue);
      expect(repo.docs['b']!.status, ReportStatus.accepted);
    });

    test('stale status is refused instead of overwriting', () async {
      final stale = _report('a', ReportStatus.accepted);
      expect(await provider.rejectReport(stale, 'No'), isFalse);
      expect(provider.actionError, 'changed');
    });

    test('comment edit keeps the status', () async {
      expect(await provider.updateComment('b', 'Updated note'), isTrue);
      expect(repo.writes.single, {'adminComment': 'Updated note'});
      expect(repo.docs['b']!.status, ReportStatus.rejected);
      expect(await provider.updateComment('b', ''), isFalse);
    });
  });
}
