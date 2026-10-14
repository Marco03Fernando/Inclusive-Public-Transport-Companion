// Widget tests for the "Report a Condition" form (ReportFormScreen) with
// mocked GPS, camera/gallery and persistence: loading, classification,
// validation, location, photos, submission success/failure, consent,
// navigation, accessibility and Sinhala UI.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/core/localization/locale.dart';
import 'package:colombo_pal/models/condition_report.dart';
import 'package:colombo_pal/models/report_exception.dart';
import 'package:colombo_pal/screens/reports/report_form_screen.dart';
import 'package:colombo_pal/services/location_service.dart';
import 'package:colombo_pal/services/photo_service.dart';

import 'helpers/test_harness.dart';

const _routeHint = 'e.g. 138, 177 or 138A';
const _vehicleHint = 'e.g. NB-4521 or Maradana Station';
const _descHint = 'Add a short description of what you observed';

late FakeLocationService location;
late FakePhotoService photos;
late ReportTestApp app;

Future<void> pumpForm(
  WidgetTester tester, {
  AppLocale locale = AppLocale.en,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    app.build(
      ReportFormScreen(locationService: location, photoService: photos),
      locale: locale,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String hint, String text) async {
  final field = find.widgetWithText(TextField, hint);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> chooseReportType(WidgetTester tester, String label) async {
  await tapVisible(tester, find.text('Select a report type'));
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Fills every required field with valid values.
Future<void> fillValidForm(WidgetTester tester) async {
  await chooseReportType(tester, 'Accessibility Issue');
  await enterField(tester, _routeHint, ' 138 a ');
  await tapVisible(tester, find.text('Bus'));
  await enterField(tester, _vehicleHint, 'NB-1234');
  await tapVisible(tester, find.byTooltip('Use current location'));
  await tapVisible(tester, find.text('Broken lift / ramp'));
  await enterField(tester, _descHint, 'The ramp is bent and will not lower.');
}

Future<void> submit(WidgetTester tester) =>
    tapVisible(tester, find.text('Submit report'));

void main() {
  setUp(() {
    location = FakeLocationService();
    photos = FakePhotoService();
    app = ReportTestApp();
  });

  group('loading and navigation', () {
    reportWidgetTest('shows every section of the form', (tester) async {
      await pumpForm(tester);
      for (final text in [
        'Report a Condition',
        'Report Type',
        'Select a report type',
        'Bus Route Number',
        'What are you reporting?',
        'Bus',
        'Station',
        'Rest area',
        'Vehicle number or location',
        'Location',
        'Condition type',
        'Broken lift / ramp',
        'No priority seat',
        'Description',
        'Photo (optional)',
        'Community sharing',
        'Submit report',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(find.bySemanticsLabel('Emergency SOS'), findsOneWidget);
    });

    reportWidgetTest('back returns a passenger to Home', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('HOME SCREEN'), findsOneWidget);
    });
  });

  group('report classification', () {
    reportWidgetTest('nothing is preselected', (tester) async {
      await pumpForm(tester);
      expect(find.text('Select a report type'), findsOneWidget);
    });

    reportWidgetTest('offers exactly the two report types', (tester) async {
      await pumpForm(tester);
      await tapVisible(tester, find.text('Select a report type'));
      expect(find.text('Positive Accessibility Feedback'), findsWidgets);
      expect(find.text('Accessibility Issue'), findsWidgets);
      expect(find.text('Unclassified'), findsNothing);
    });

    reportWidgetTest('explains the chosen type underneath', (tester) async {
      await pumpForm(tester);
      await chooseReportType(tester, 'Positive Accessibility Feedback');
      expect(
        find.textContaining('An accessibility feature is present and working'),
        findsOneWidget,
      );
    });
  });

  group('validation', () {
    reportWidgetTest('empty submission shows every required-field error '
        'and writes nothing', (tester) async {
      await pumpForm(tester);
      await submit(tester);
      for (final message in [
        'Choose a report type.',
        'Enter the bus route number (e.g. 138 or 138A).',
        'Choose what you are reporting.',
        'Enter a vehicle or station number.',
        'Add a location using the GPS button.',
        'Choose a condition type.',
        'Please describe what you saw.',
      ]) {
        expect(find.text(message), findsOneWidget, reason: message);
      }
      expect(app.repository.createCalls, isEmpty);
      expect(find.text('CONFIRMATION SCREEN'), findsNothing);
    });

    reportWidgetTest('invalid route number is explained, and the error '
        'clears as the user edits', (tester) async {
      await pumpForm(tester);
      await enterField(tester, _routeHint, 'Galle Road');
      await submit(tester);
      expect(
        find.text('A bus route number must include a number (e.g. 138).'),
        findsOneWidget,
      );
      await enterField(tester, _routeHint, '138');
      expect(
        find.text('A bus route number must include a number (e.g. 138).'),
        findsNothing,
      );
    });

    reportWidgetTest('short description is rejected', (tester) async {
      await pumpForm(tester);
      await enterField(tester, _descHint, 'too short');
      await submit(tester);
      expect(
        find.text('Please add a few more details (at least 10 characters).'),
        findsOneWidget,
      );
    });

    reportWidgetTest('vehicle number is optional for "Other"', (tester) async {
      await pumpForm(tester);
      await tapVisible(tester, find.text('Other').first);
      await submit(tester);
      expect(find.text('Enter a vehicle or station number.'), findsNothing);
    });

    reportWidgetTest('picking a missing chip clears its error', (tester) async {
      await pumpForm(tester);
      await submit(tester);
      expect(find.text('Choose what you are reporting.'), findsOneWidget);
      await tapVisible(tester, find.text('Station'));
      expect(find.text('Choose what you are reporting.'), findsNothing);
    });
  });

  group('location', () {
    reportWidgetTest('GPS fills the location field', (tester) async {
      await pumpForm(tester);
      await tapVisible(tester, find.byTooltip('Use current location'));
      expect(location.calls, 1);
      expect(
        find.widgetWithText(TextField, 'Current location attached'),
        findsOneWidget,
      );
    });

    reportWidgetTest('GPS failure shows the service message', (tester) async {
      location.error = LocationServiceException(
        'Location services are turned off. Please turn on GPS and try again.',
      );
      await pumpForm(tester);
      await tapVisible(tester, find.byTooltip('Use current location'));
      expect(
        find.text(
          'Location services are turned off. Please turn on GPS and try again.',
        ),
        findsOneWidget,
      );
    });

    reportWidgetTest('permanently denied permission offers app settings', (
      tester,
    ) async {
      location.error = LocationServiceException(
        'Location permission is permanently denied.',
        permanentlyDenied: true,
      );
      await pumpForm(tester);
      await tapVisible(tester, find.byTooltip('Use current location'));
      expect(find.text('Location permission required'), findsOneWidget);
      // Regression: the field no longer spins behind the dialog.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('Location permission required'), findsNothing);
    });
  });

  group('photo (mocked camera / gallery)', () {
    late String photoPath;

    setUp(() {
      // A real 1×1 PNG so the preview has a valid file to point at.
      final file =
          File(
            '${Directory.systemTemp.createTempSync('report_photo').path}/p.png',
          )..writeAsBytesSync(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
            ),
          );
      photoPath = file.path;
    });

    reportWidgetTest('gallery photo is attached and can be replaced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      photos.path = photoPath;
      await pumpForm(tester);
      expect(find.bySemanticsLabel('Tap to add photo'), findsOneWidget);
      await tapVisible(tester, find.text('+ attach photo'));
      expect(find.text('Take photo'), findsOneWidget);
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(photos.requests, [PhotoSource.gallery]);
      expect(find.text('Tap to replace'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Photo added, tap to replace'),
        findsOneWidget,
      );
      handle.dispose();
    });

    reportWidgetTest('camera can be chosen', (tester) async {
      photos.path = photoPath;
      await pumpForm(tester);
      await tapVisible(tester, find.text('+ attach photo'));
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(photos.requests, [PhotoSource.camera]);
    });

    reportWidgetTest('cancelling the picker leaves the form unchanged', (
      tester,
    ) async {
      photos.path = null;
      await pumpForm(tester);
      await tapVisible(tester, find.text('+ attach photo'));
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(find.text('+ attach photo'), findsOneWidget);
    });

    reportWidgetTest('picker failure is explained in a snackbar', (
      tester,
    ) async {
      photos.error = PhotoServiceException(
        'Could not open the camera. Check camera permissions and try again.',
      );
      await pumpForm(tester);
      await tapVisible(tester, find.text('+ attach photo'));
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not open the camera. Check camera permissions and try again.',
        ),
        findsOneWidget,
      );
    });

    reportWidgetTest('photo upload failure offers "Submit without photo"', (
      tester,
    ) async {
      photos.path = photoPath;
      app.repository.createError = const ReportException(
        ReportFailure.storage,
        'Could not upload your photo. Please try again.',
      );
      await pumpForm(tester);
      await fillValidForm(tester);
      await tapVisible(tester, find.text('+ attach photo'));
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      await submit(tester);

      expect(
        find.text('Could not upload your photo. Please try again.'),
        findsOneWidget,
      );
      expect(app.repository.createCalls.single.photoPath, photoPath);

      app.repository.createError = null;
      await tester.tap(find.text('Submit without photo'));
      await tester.pumpAndSettle();
      expect(app.repository.createCalls, hasLength(2));
      expect(app.repository.createCalls.last.photoPath, isNull);
      expect(find.text('CONFIRMATION SCREEN'), findsOneWidget);
    });
  });

  group('submission', () {
    reportWidgetTest('valid report is saved for the signed-in user and the '
        'confirmation screen opens', (tester) async {
      await pumpForm(tester);
      await fillValidForm(tester);
      await submit(tester);

      expect(find.text('CONFIRMATION SCREEN'), findsOneWidget);
      final sent = app.repository.createCalls.single;
      expect(sent.userId, 'user-a');
      expect(sent.reportType, ReportType.issue);
      expect(sent.routeNumber, '138 a');
      expect(sent.routeId, '138A');
      expect(sent.subject, ReportSubject.bus);
      expect(sent.vehicleOrStationNumber, 'NB-1234');
      expect(sent.conditionType, ConditionType.brokenRamp);
      expect(sent.location.hasCoordinates, isTrue);
      expect(sent.status, ReportStatus.underReview);
      expect(sent.shareWithCommunity, isFalse);
      expect(app.reports.lastSubmitted?.id, isNotEmpty);
    });

    reportWidgetTest('a save failure keeps the user on the form with the '
        'reason', (tester) async {
      app.repository.createError = const ReportException(
        ReportFailure.network,
        'Could not save your report. Check your internet connection and try again.',
      );
      await pumpForm(tester);
      await fillValidForm(tester);
      await submit(tester);

      expect(find.textContaining('Check your internet connection'), findsOne);
      expect(find.text('CONFIRMATION SCREEN'), findsNothing);
      expect(find.text('Submit without photo'), findsNothing);
      // The button is usable again for a retry.
      expect(find.text('Submit report'), findsOneWidget);
    });

    reportWidgetTest('signed-out user cannot submit', (tester) async {
      app.auth.uid = null;
      await pumpForm(tester);
      await fillValidForm(tester);
      await submit(tester);
      expect(find.text('Please sign in again to continue.'), findsOneWidget);
      expect(app.repository.createCalls, isEmpty);
    });
  });

  group('community sharing consent', () {
    reportWidgetTest('off by default; turning it on shares anonymously when '
        'there is no profile name', (tester) async {
      await pumpForm(tester);
      expect(find.text('Show my name'), findsNothing);

      await tapVisible(tester, find.text('Share with the community'));
      expect(
        find.text('Your report will be shared as Anonymous Contributor.'),
        findsOneWidget,
      );

      await fillValidForm(tester);
      await submit(tester);
      final sent = app.repository.createCalls.single;
      expect(sent.shareWithCommunity, isTrue);
      expect(sent.publicDisplayName, isNull);
    });
  });

  group('accessibility and language', () {
    reportWidgetTest('validation errors are live regions for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpForm(tester);
      await submit(tester);
      final node = tester.getSemantics(
        find.text('Choose what you are reporting.'),
      );
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    reportWidgetTest('subject chips expose button + selected state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpForm(tester);
      await tapVisible(tester, find.text('Station'));
      final data = tester
          .getSemantics(find.bySemanticsLabel('Station'))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });

    reportWidgetTest('chips meet the 48 dp minimum touch target', (
      tester,
    ) async {
      await pumpForm(tester);
      expect(tester.getSize(find.text('Bus').first).height, lessThan(48));
      final chip = find.ancestor(
        of: find.text('Bus').first,
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(chip.first).height, greaterThanOrEqualTo(48));
    });

    reportWidgetTest('lays out without overflow at 200% text size', (
      tester,
    ) async {
      await pumpForm(tester, textScale: 2.0);
      await submit(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Choose a report type.'), findsOneWidget);
    });

    reportWidgetTest('Sinhala UI: translated labels, English fallback for '
        'untranslated keys', (tester) async {
      await pumpForm(tester, locale: AppLocale.si);
      expect(find.text('තත්ත්වයක් වාර්තා කරන්න'), findsOneWidget);
      expect(find.text('ඔබ වාර්තා කරන්නේ කුමක්ද?'), findsOneWidget);
      expect(find.text('වාර්තාව යවන්න'), findsOneWidget);
      // These keys have no Sinhala translation yet (see the Milestone 3
      // findings) and fall back to English rather than showing raw keys.
      expect(find.text('Report Type'), findsOneWidget);
      expect(find.text('Bus Route Number'), findsOneWidget);
    });
  });
}
