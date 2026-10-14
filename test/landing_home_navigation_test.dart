// Guards the behaviour of the redesigned landing (role select / get
// started) and passenger Home screens: every button must still lead to the
// same route, with the same role handling, as before the redesign.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:colombo_pal/core/routes.dart';
import 'package:colombo_pal/core/state/app_state.dart';
import 'package:colombo_pal/models/condition_report.dart';
import 'package:colombo_pal/screens/onboarding/role_select_screen.dart';
import 'package:colombo_pal/screens/passenger/home_screen.dart';

import 'condition_report_tests/helpers/test_harness.dart';

final _routes = <String, WidgetBuilder>{
  Routes.signupBasic: (_) => const Scaffold(body: Text('SIGNUP SCREEN')),
  Routes.login: (_) => const Scaffold(body: Text('LOGIN SCREEN')),
  Routes.planSearch: (_) => const Scaffold(body: Text('PLAN SEARCH SCREEN')),
  Routes.shareSetup: (_) => const Scaffold(body: Text('SHARE SETUP SCREEN')),
  Routes.reportMine: (_) => const Scaffold(body: Text('MY REPORTS SCREEN')),
};

Future<void> pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(412, 915) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ReportTestApp().build(screen, routes: _routes));
  await tester.pumpAndSettle();
}

AppRole roleOf(WidgetTester tester) =>
    tester.element(find.byType(MaterialApp)).read<AppState>().role;

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('landing (get started)', () {
    reportWidgetTest('shows brand, headline, benefits and actions', (
      tester,
    ) async {
      await pump(tester, const RoleSelectScreen());
      for (final text in [
        'Travel independently.\nFeel empowered.',
        'Travel safely and confidently around Colombo',
        'Accessible routes',
        'Volunteer help',
        'Live reports',
        'Get Started',
        'Log in',
        'Continue as Guest',
      ]) {
        expect(
          find.text(text, findRichText: true),
          findsOneWidget,
          reason: text,
        );
      }
      expect(find.bySemanticsLabel('Colombo Pal'), findsOneWidget);
    });

    for (final (label, role) in [
      ('Passenger', AppRole.passenger),
      ('Volunteer', AppRole.volunteer),
    ]) {
      reportWidgetTest('Get Started → $label sets the role and opens sign-up', (
        tester,
      ) async {
        await pump(tester, const RoleSelectScreen());
        await tapVisible(tester, find.text('Get Started'));
        expect(find.text('I am registering as a'), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text('SIGNUP SCREEN'), findsOneWidget);
        expect(roleOf(tester), role);
      });
    }

    reportWidgetTest('dismissing the role sheet keeps the user on the page', (
      tester,
    ) async {
      await pump(tester, const RoleSelectScreen());
      await tapVisible(tester, find.text('Get Started'));
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();
      expect(find.text('SIGNUP SCREEN'), findsNothing);
      expect(find.text('Get Started'), findsOneWidget);
    });

    reportWidgetTest('Log in opens the login screen', (tester) async {
      await pump(tester, const RoleSelectScreen());
      await tapVisible(tester, find.text('Log in'));
      expect(find.text('LOGIN SCREEN'), findsOneWidget);
    });
  });

  group('passenger home', () {
    for (final (label, screen) in [
      ('Plan Journey', 'PLAN SEARCH SCREEN'),
      ('Share Journey', 'SHARE SETUP SCREEN'),
      ('Report a Condition', 'REPORT FORM SCREEN'),
    ]) {
      reportWidgetTest('$label card keeps its route', (tester) async {
        await pump(tester, const HomeScreen());
        await tapVisible(tester, find.text(label));
        expect(find.text(screen), findsOneWidget);
      });
    }

    reportWidgetTest('keeps header actions; shows no sample data or role '
        'cards', (tester) async {
      await pump(tester, const HomeScreen());
      expect(find.byTooltip('Accessibility settings'), findsOneWidget);
      expect(find.text('Where would you like to go today?'), findsOneWidget);
      for (final sample in [
        'Kamala Fernando',
        'Lift out of service',
        'Bambalapitiya',
        'Nimal Perera',
        'Passenger',
        'Volunteer',
      ]) {
        expect(
          find.textContaining(sample, findRichText: true),
          findsNothing,
          reason: sample,
        );
      }
    });

    reportWidgetTest("recent activity shows the signed-in user's latest "
        'reports only', (tester) async {
      final app = ReportTestApp();
      app.repository
        ..seed(sampleReport(id: 'old', createdAt: DateTime(2026, 9, 1)))
        ..seed(
          ConditionReport.fromJson(
            sampleReport(id: 'new', createdAt: DateTime(2026, 10, 9)).toJson()
              ..['vehicleOrStationNumber'] = 'NEWEST-1',
          ),
        )
        ..seed(
          ConditionReport.fromJson(
            sampleReport(id: 'b', userId: 'user-b').toJson()
              ..['vehicleOrStationNumber'] = 'OTHER-USER',
          ),
        );
      tester.view.physicalSize = const Size(412, 915) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app.build(const HomeScreen(), routes: _routes));
      app.reports.syncSession(userId: 'user-a');
      await tester.pumpAndSettle();

      expect(find.textContaining('NEWEST-1'), findsOneWidget);
      expect(find.textContaining('OTHER-USER'), findsNothing);
      await tapVisible(tester, find.text('View all'));
      expect(find.text('MY REPORTS SCREEN'), findsOneWidget);
    });

    reportWidgetTest('recent activity empty state', (tester) async {
      final app = ReportTestApp();
      await tester.pumpWidget(app.build(const HomeScreen(), routes: _routes));
      app.reports.syncSession(userId: 'user-a');
      await tester.pumpAndSettle();
      expect(
        find.text('No activity yet. Reports you submit will appear here.'),
        findsOneWidget,
      );
    });

    reportWidgetTest('no overflow at 200% text on a small phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      for (final screen in [const HomeScreen(), const RoleSelectScreen()]) {
        await tester.pumpWidget(
          ReportTestApp().build(screen, routes: _routes, textScale: 2),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
