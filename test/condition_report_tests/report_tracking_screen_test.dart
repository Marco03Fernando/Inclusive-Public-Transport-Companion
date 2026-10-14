// Widget tests for report tracking ("My Reports", ReportMineScreen) with a
// mocked repository: user-scoped history, status groups and filters, live
// admin decisions, loading / empty / error states, accessibility and
// Sinhala UI.
import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/core/localization/locale.dart';
import 'package:colombo_pal/models/condition_report.dart';
import 'package:colombo_pal/models/report_exception.dart';
import 'package:colombo_pal/models/report_filters.dart';
import 'package:colombo_pal/screens/reports/report_mine_screen.dart';

import 'helpers/test_harness.dart';

late ReportTestApp app;

ConditionReport _report(
  String id,
  ReportStatus status, {
  String userId = 'user-a',
  String vehicle = 'NB-1234',
  ReportSubject subject = ReportSubject.bus,
}) => ConditionReport.fromJson(
  sampleReport(
    id: id,
    userId: userId,
    status: status,
    subject: subject,
  ).toJson()..['vehicleOrStationNumber'] = vehicle,
);

Future<void> pumpMyReports(
  WidgetTester tester, {
  StatusFilter initialStatus = StatusFilter.all,
  AppLocale locale = AppLocale.en,
}) async {
  await tester.pumpWidget(
    app.build(ReportMineScreen(initialStatus: initialStatus), locale: locale),
  );
  // What app.dart's ChangeNotifierProxyProvider does on sign-in.
  app.reports.syncSession(userId: app.auth.uid);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    app = ReportTestApp();
    app.repository
      ..seed(_report('p1', ReportStatus.underReview, vehicle: 'NB-1111'))
      ..seed(_report('a1', ReportStatus.accepted, vehicle: 'NB-2222'))
      ..seed(_report('x1', ReportStatus.rejected, vehicle: 'NB-3333'))
      ..seed(
        _report(
          'other',
          ReportStatus.accepted,
          userId: 'user-b',
          vehicle: 'OTHER-USER',
        ),
      );
  });

  reportWidgetTest('shows only the signed-in user\'s reports, grouped by '
      'status', (tester) async {
    await pumpMyReports(tester);
    expect(find.text('My Reports'), findsOneWidget);
    expect(find.textContaining('NB-1111'), findsOneWidget);
    expect(find.textContaining('NB-2222'), findsOneWidget);
    expect(find.textContaining('NB-3333'), findsOneWidget);
    expect(find.textContaining('OTHER-USER'), findsNothing);
    expect(app.repository.watchedUserIds, ['user-a']);

    // Group headings (the status chips repeat "Under review (1)" etc.).
    expect(find.text('Verified by admin (1)'), findsOneWidget);
    expect(find.text('Under review (1)'), findsNWidgets(2));
    expect(find.text('Rejected (1)'), findsNWidgets(2));
    expect(find.text('Verified (1)'), findsOneWidget);
    expect(find.text('Showing 3 of 3 reports'), findsOneWidget);
  });

  reportWidgetTest('each card shows type, route and status', (tester) async {
    await pumpMyReports(tester);
    expect(find.text('Accessibility Issue · Bus route 138A'), findsNWidgets(3));
    expect(find.text('Under Review'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
  });

  reportWidgetTest('status filter narrows the list', (tester) async {
    await pumpMyReports(tester);
    await tester.tap(find.text('Rejected (1)').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('NB-3333'), findsOneWidget);
    expect(find.textContaining('NB-1111'), findsNothing);
    expect(find.text('Showing 1 of 3 reports'), findsOneWidget);
  });

  reportWidgetTest('opening pre-filtered on verified reports (dashboard '
      'shortcut)', (tester) async {
    await pumpMyReports(tester, initialStatus: StatusFilter.verified);
    expect(find.textContaining('NB-2222'), findsOneWidget);
    expect(find.textContaining('NB-1111'), findsNothing);
  });

  reportWidgetTest('a filter with no matches offers to clear filters', (
    tester,
  ) async {
    await pumpMyReports(tester);
    await tester.tap(find.text('Stations'));
    await tester.pumpAndSettle();
    expect(find.text('No matching reports'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 3 of 3 reports'), findsOneWidget);
  });

  reportWidgetTest('an admin decision appears without refreshing', (
    tester,
  ) async {
    await pumpMyReports(tester);
    await app.repository.updateReportStatus(
      reportId: 'p1',
      status: ReportStatus.accepted,
      adminComment: 'Verified on site',
    );
    await tester.pumpAndSettle();
    expect(find.text('Verified by admin (2)'), findsOneWidget);
    expect(find.text('Under review (1)'), findsNothing);
  });

  reportWidgetTest('empty history explains what will appear', (tester) async {
    app = ReportTestApp();
    await pumpMyReports(tester);
    expect(find.text('No reports yet'), findsOneWidget);
    expect(find.text('Reports you submit will appear here.'), findsOneWidget);
  });

  reportWidgetTest('load failure shows the reason and can retry', (
    tester,
  ) async {
    app.repository.watchError = const ReportException(
      ReportFailure.network,
      'Could not load your reports. Check your internet connection and try again.',
    );
    await pumpMyReports(tester);
    expect(find.textContaining('Could not load your reports'), findsOneWidget);

    app.repository.watchError = null;
    await tester.tap(find.text('Try again'));
    // Re-subscribing first awaits cancelling the failed subscription, which
    // completes on the real event loop — let it run.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.textContaining('NB-1111'), findsOneWidget);
  });

  reportWidgetTest('each card is one screen-reader item that includes its '
      'status', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMyReports(tester);
    final card = tester.getSemantics(find.textContaining('NB-2222'));
    expect(card.label, contains('NB-2222'));
    expect(card.label, contains('Accessibility Issue · Bus route 138A'));
    expect(card.label, contains('Status Accepted'));
    // The status is read once, not as both "Accepted" and "Status Accepted".
    expect('Accepted'.allMatches(card.label).length, 1);
    handle.dispose();
  });

  reportWidgetTest('Sinhala UI title', (tester) async {
    await pumpMyReports(tester, locale: AppLocale.si);
    expect(find.text('මගේ වාර්තා'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  reportWidgetTest('back returns a passenger to Home', (tester) async {
    await pumpMyReports(tester);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });
}
