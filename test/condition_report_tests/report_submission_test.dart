// Submission pipeline with mocked persistence (no Firebase):
// ConditionReportService validation → ReportsProvider submission, failure
// handling, user-scoped history, live status updates and deletion; plus
// the on-device LocalConditionReportRepository.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colombo_pal/models/condition_report.dart';
import 'package:colombo_pal/models/report_exception.dart';
import 'package:colombo_pal/providers/reports_provider.dart';
import 'package:colombo_pal/repositories/local_condition_report_repository.dart';
import 'package:colombo_pal/services/condition_report_service.dart';

import 'helpers/test_harness.dart';

/// Waits for scheduled microtasks / stream deliveries.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('ConditionReportService validation (defence in depth)', () {
    late FakeReportRepository repo;
    late ConditionReportService service;

    setUp(() {
      repo = FakeReportRepository();
      service = ConditionReportService(repository: repo);
    });

    Future<ReportException> rejected(ConditionReport report) async {
      try {
        await service.createReport(report);
      } on ReportException catch (e) {
        return e;
      }
      fail('expected a ReportException');
    }

    test('a valid report reaches the repository', () async {
      final saved = await service.createReport(sampleReport(id: ''));
      expect(saved.id, isNotEmpty);
      expect(repo.createCalls, hasLength(1));
    });

    test('no signed-in user → auth failure, nothing written', () async {
      final e = await rejected(sampleReport(userId: ''));
      expect(e.failure, ReportFailure.auth);
      expect(repo.createCalls, isEmpty);
    });

    test('unclassified report → validation failure', () async {
      final e = await rejected(sampleReport(reportType: ReportType.unknown));
      expect(e.failure, ReportFailure.validation);
      expect(e.message, 'Please choose a report type.');
    });

    test('invalid or tampered route → validation failure', () async {
      final bad = await rejected(sampleReport(routeNumber: 'ABC'));
      expect(bad.failure, ReportFailure.validation);

      // routeId that doesn't match the normalized routeNumber.
      final tampered = ConditionReport.fromJson(
        sampleReport().toJson()..['routeId'] = '999',
      );
      final e = await rejected(tampered);
      expect(e.message, 'Please check the bus route number.');
    });

    test('blank description → validation failure', () async {
      final report = ConditionReport.fromJson(
        sampleReport().toJson()..['description'] = '   ',
      );
      final e = await rejected(report);
      expect(e.message, 'Please describe what you saw.');
    });
  });

  group('ReportsProvider.submitReport', () {
    late FakeAuthService auth;
    late FakeReportRepository repo;
    late ReportsProvider provider;

    setUp(() {
      auth = FakeAuthService(uid: 'user-a');
      repo = FakeReportRepository();
      provider = ReportsProvider(
        service: ConditionReportService(repository: repo),
        authService: auth,
      );
    });

    tearDown(() async {
      provider.dispose();
      await repo.dispose();
    });

    test('attaches the signed-in UID and starts under review', () async {
      final ok = await provider.submitReport(sampleReport(id: '', userId: ''));
      expect(ok, isTrue);
      expect(repo.createCalls.single.userId, 'user-a');
      expect(provider.lastSubmitted?.status, ReportStatus.underReview);
      expect(provider.reports.single.id, provider.lastSubmitted!.id);
      expect(provider.submitError, isNull);
    });

    test('a photo path is handed to the repository for upload', () async {
      final report = sampleReport(
        id: '',
        userId: '',
      ).copyWith(photoPath: '/data/photo.jpg');
      await provider.submitReport(report);
      expect(repo.createCalls.single.photoPath, '/data/photo.jpg');
      expect(provider.lastSubmitted?.photoUrl, isNotNull);
    });

    test('signed out → auth failure with a user-facing message', () async {
      auth.uid = null;
      final ok = await provider.submitReport(sampleReport(userId: ''));
      expect(ok, isFalse);
      expect(provider.submitFailure, ReportFailure.auth);
      expect(provider.submitError, 'Please sign in again to continue.');
      expect(repo.createCalls, isEmpty);
    });

    test('storage (photo upload) failure is reported as such', () async {
      repo.createError = const ReportException(
        ReportFailure.storage,
        'Could not upload your photo. Please try again.',
      );
      final ok = await provider.submitReport(sampleReport(userId: ''));
      expect(ok, isFalse);
      expect(provider.submitFailure, ReportFailure.storage);
      expect(provider.submitError, contains('upload your photo'));
      expect(provider.lastSubmitted, isNull);
    });

    test('network failure keeps the message from the repository', () async {
      repo.createError = const ReportException(
        ReportFailure.network,
        'Could not save your report. Check your internet connection and try again.',
      );
      await provider.submitReport(sampleReport(userId: ''));
      expect(provider.submitFailure, ReportFailure.network);
      expect(provider.submitError, contains('internet connection'));
    });

    test('unexpected errors become a generic, safe message', () async {
      repo.createError = StateError('internal detail');
      await provider.submitReport(sampleReport(userId: ''));
      expect(provider.submitFailure, ReportFailure.unknown);
      expect(
        provider.submitError,
        'Could not submit your report. Please try again.',
      );
      expect(provider.submitError, isNot(contains('internal detail')));
    });

    test('a retry after failure clears the previous error', () async {
      repo.createError = const ReportException(ReportFailure.network, 'x');
      await provider.submitReport(sampleReport(userId: ''));
      repo.createError = null;
      expect(await provider.submitReport(sampleReport(userId: '')), isTrue);
      expect(provider.submitError, isNull);
      expect(provider.submitFailure, isNull);
    });
  });

  group('report history and user-specific access', () {
    late FakeAuthService auth;
    late FakeReportRepository repo;
    late ReportsProvider provider;

    setUp(() {
      auth = FakeAuthService(uid: 'user-a');
      repo = FakeReportRepository()
        ..seed(sampleReport(id: 'a1', userId: 'user-a'))
        ..seed(
          sampleReport(
            id: 'a2',
            userId: 'user-a',
            createdAt: DateTime(2026, 10, 5),
          ),
        )
        ..seed(sampleReport(id: 'b1', userId: 'user-b'));
      provider = ReportsProvider(
        service: ConditionReportService(repository: repo),
        authService: auth,
      );
    });

    tearDown(() async {
      provider.dispose();
      await repo.dispose();
    });

    test(
      'only the signed-in user\'s reports are requested and shown',
      () async {
        provider.syncSession(userId: 'user-a');
        await settle();
        await settle();
        expect(repo.watchedUserIds, ['user-a']);
        expect(provider.reports.map((r) => r.id), ['a2', 'a1']);
        expect(provider.reports.every((r) => r.userId == 'user-a'), isTrue);
      },
    );

    test('an admin decision updates My Reports live', () async {
      provider.syncSession(userId: 'user-a');
      await settle();
      await settle();
      await repo.updateReportStatus(
        reportId: 'a1',
        status: ReportStatus.accepted,
        adminComment: 'Confirmed by inspection',
      );
      await settle();
      final a1 = provider.reports.firstWhere((r) => r.id == 'a1');
      expect(a1.status, ReportStatus.accepted);
      expect(a1.adminComment, 'Confirmed by inspection');
    });

    test(
      'signing out clears the list (no data leaks to the next user)',
      () async {
        provider.syncSession(userId: 'user-a');
        await settle();
        await settle();
        expect(provider.reports, isNotEmpty);

        provider.syncSession(userId: null);
        await settle();
        expect(provider.reports, isEmpty);
        expect(provider.lastSubmitted, isNull);
      },
    );

    test('switching accounts shows only the new account\'s reports', () async {
      provider.syncSession(userId: 'user-a');
      await settle();
      await settle();
      auth.uid = 'user-b';
      provider.syncSession(userId: 'user-b');
      await settle();
      await settle();
      expect(provider.reports.map((r) => r.id), ['b1']);
    });

    test('a load failure surfaces the repository message', () async {
      repo.watchError = const ReportException(
        ReportFailure.missingIndex,
        'Could not load your reports: the database index for reports is still being set up.',
      );
      provider.syncSession(userId: 'user-a');
      await settle();
      await settle();
      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('index'));
    });

    test('deleting a report removes it from history', () async {
      provider.syncSession(userId: 'user-a');
      await settle();
      await settle();
      expect(await provider.deleteReport('a1'), isTrue);
      expect(provider.reports.map((r) => r.id), isNot(contains('a1')));
    });
  });

  group('LocalConditionReportRepository (on-device fallback)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('stores reports per user, newest first', () async {
      final repo = LocalConditionReportRepository();
      final saved = await repo.createReport(sampleReport(id: ''));
      expect(saved.id, isNotEmpty);
      await repo.createReport(
        sampleReport(id: 'x', createdAt: DateTime(2026, 10, 9)),
      );
      await repo.createReport(sampleReport(id: 'other', userId: 'user-b'));

      final mine = await repo.getUserReports('user-a');
      expect(mine.map((r) => r.id).first, 'x');
      expect(mine.every((r) => r.userId == 'user-a'), isTrue);
      expect(await repo.getUserReports('user-b'), hasLength(1));
    });

    test('status update and delete', () async {
      final repo = LocalConditionReportRepository();
      await repo.createReport(sampleReport(id: 'r9'));
      final updated = await repo.updateReportStatus(
        reportId: 'r9',
        status: ReportStatus.rejected,
        adminComment: 'Duplicate',
      );
      expect(updated.status, ReportStatus.rejected);
      expect(updated.adminComment, 'Duplicate');

      await repo.deleteReport('r9');
      expect(await repo.getUserReports('user-a'), isEmpty);
    });

    test('updating a missing report fails loudly', () async {
      final repo = LocalConditionReportRepository();
      expect(
        () => repo.updateReportStatus(
          reportId: 'nope',
          status: ReportStatus.accepted,
        ),
        throwsStateError,
      );
    });
  });
}
