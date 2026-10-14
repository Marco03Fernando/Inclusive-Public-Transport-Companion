// Condition report data model: classification, bus routes, draft →
// report conversion, persistence round-trips and display labels.
//
// The first group was moved here from test/roles_and_reports_test.dart.
import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/models/condition_report.dart';

ConditionReportDraft _completeDraft() => ConditionReportDraft(
  reportType: ReportType.issue,
  routeNumber: ' 138 a ',
  subject: ReportSubject.bus,
  vehicleOrStationNumber: ' nb-1234 ',
  reportLocation: const ReportLocation(
    latitude: 6.9,
    longitude: 79.8,
    label: 'Current location attached',
  ),
  conditionType: ConditionType.brokenRamp,
  description: '  Ramp is bent and will not lower.  ',
);

void main() {
  group('condition reports (moved from roles_and_reports_test)', () {
    test('existing Firestore enum names still parse', () {
      for (final name in ['brokenRamp', 'noSeat', 'overcrowded', 'unsafe']) {
        expect(ConditionType.values.byName(name).name, name);
      }
      for (final name in ['underReview', 'verified', 'accepted', 'rejected']) {
        expect(ReportStatus.values.byName(name).name, name);
      }
    });

    // Previously failed: the draft predated the required report type and
    // bus route, so ConditionReport.fromDraft's assertion fired.
    test('form draft becomes an under-review report', () {
      final report = ConditionReport.fromDraft(_completeDraft());
      expect(report.status, ReportStatus.underReview);
      expect(report.title, 'Bus nb-1234');
      expect(report.location.hasCoordinates, isTrue);
      expect(report.id, isEmpty);
    });
  });

  group('ReportType classification', () {
    test('stored values parse; anything else is unclassified', () {
      expect(ReportType.parse('positive'), ReportType.positive);
      expect(ReportType.parse('issue'), ReportType.issue);
      for (final raw in [null, '', 'Positive', 'ISSUE', 42, 'unknown']) {
        expect(ReportType.parse(raw), ReportType.unknown, reason: '$raw');
      }
    });

    test('only positive and issue are selectable on the form', () {
      expect(ReportType.selectable, [ReportType.positive, ReportType.issue]);
      expect(ReportType.unknown.isClassified, isFalse);
    });

    test('labels match the documented wording', () {
      expect(ReportType.positive.label, 'Positive Accessibility Feedback');
      expect(ReportType.issue.label, 'Accessibility Issue');
      expect(ReportType.unknown.label, 'Unclassified');
    });
  });

  group('BusRoute', () {
    test('normalize removes whitespace and upper-cases', () {
      expect(BusRoute.normalize(' 138 a '), '138A');
      expect(BusRoute.normalize('ex1-1'), 'EX1-1');
    });

    test('displayValue keeps what the user typed, tidied', () {
      expect(BusRoute.displayValue('  138   A '), '138 A');
    });

    test('accepts typical Colombo route numbers', () {
      for (final route in ['138', '177', '138A', 'EX1-1', '100/2', '1']) {
        expect(BusRoute.validate(route), isNull, reason: route);
      }
    });

    test('rejects empty, letters-only, too long and symbol inputs', () {
      expect(BusRoute.validate(null), contains('Enter the bus route'));
      expect(BusRoute.validate('   '), contains('Enter the bus route'));
      expect(BusRoute.validate('ABC'), contains('must include a number'));
      expect(BusRoute.validate('1234567890123'), contains('too long'));
      expect(BusRoute.validate('138#'), contains('Use only letters'));
      expect(BusRoute.validate('138--A'), contains('Use only letters'));
      expect(BusRoute.validate('-138'), contains('Use only letters'));
    });
  });

  group('ConditionReport.fromDraft', () {
    test('trims and normalizes every field', () {
      final report = ConditionReport.fromDraft(_completeDraft());
      expect(report.reportType, ReportType.issue);
      expect(report.routeNumber, '138 a');
      expect(report.routeId, '138A');
      expect(report.vehicleOrStationNumber, 'nb-1234');
      expect(report.description, 'Ramp is bent and will not lower.');
      expect(report.userId, isEmpty, reason: 'filled in by ReportsProvider');
      expect(report.hasRoute, isTrue);
    });

    test('a typed location label is used when there is no GPS fix', () {
      final draft = _completeDraft()
        ..reportLocation = null
        ..location = '  Maradana Station  ';
      expect(
        ConditionReport.fromDraft(draft).location.label,
        'Maradana Station',
      );
    });

    test('community consent defaults to private', () {
      final report = ConditionReport.fromDraft(_completeDraft());
      expect(report.shareWithCommunity, isFalse);
      expect(report.publicDisplayName, isNull);
    });

    test('a public name is dropped unless sharing is on', () {
      final draft = _completeDraft()..publicDisplayName = 'Kamala';
      expect(ConditionReport.fromDraft(draft).publicDisplayName, isNull);

      draft.shareWithCommunity = true;
      final shared = ConditionReport.fromDraft(draft);
      expect(shared.shareWithCommunity, isTrue);
      expect(shared.publicDisplayName, 'Kamala');

      draft.publicDisplayName = '   ';
      expect(ConditionReport.fromDraft(draft).publicDisplayName, isNull);
    });

    test('the draft summary title matches the submitted title', () {
      final draft = _completeDraft();
      expect(draft.summaryTitle, 'Bus nb-1234');
      draft.vehicleOrStationNumber = '';
      draft.subject = ReportSubject.restArea;
      expect(draft.summaryTitle, 'Rest area');
    });
  });

  group('persistence round-trip', () {
    test('toJson / fromJson keeps every field', () {
      final original =
          ConditionReport.fromDraft(
            _completeDraft()
              ..shareWithCommunity = true
              ..publicDisplayName = 'Kamala',
          ).copyWith(
            id: 'abc',
            userId: 'user-a',
            photoUrl: 'https://example.test/p.jpg',
            status: ReportStatus.accepted,
            adminComment: 'Confirmed',
          );
      final copy = ConditionReport.fromJson(original.toJson());
      expect(copy.id, 'abc');
      expect(copy.userId, 'user-a');
      expect(copy.reportType, ReportType.issue);
      expect(copy.routeId, '138A');
      expect(copy.subject, ReportSubject.bus);
      expect(copy.conditionType, ConditionType.brokenRamp);
      expect(copy.location.latitude, 6.9);
      expect(copy.photoUrl, 'https://example.test/p.jpg');
      expect(copy.status, ReportStatus.accepted);
      expect(copy.adminComment, 'Confirmed');
      expect(copy.shareWithCommunity, isTrue);
      expect(copy.publicDisplayName, 'Kamala');
      expect(copy.createdAt, original.createdAt);
    });

    test('the local photo path is never persisted', () {
      final report = ConditionReport.fromDraft(
        _completeDraft()..photoPath = '/tmp/p.jpg',
      );
      expect(report.photoPath, '/tmp/p.jpg');
      expect(report.toJson().containsKey('photoPath'), isFalse);
    });

    test('legacy JSON without classification reads as unclassified', () {
      final json = ConditionReport.fromDraft(_completeDraft()).toJson()
        ..remove('reportType')
        ..remove('routeNumber')
        ..remove('routeId')
        ..remove('shareWithCommunity')
        ..remove('status');
      final legacy = ConditionReport.fromJson(json);
      expect(legacy.reportType, ReportType.unknown);
      expect(legacy.routeLabel, BusRoute.unassignedLabel);
      expect(legacy.hasRoute, isFalse);
      expect(legacy.shareWithCommunity, isFalse);
      expect(legacy.status, ReportStatus.underReview);
    });
  });

  group('status and route eligibility', () {
    ConditionReport withStatus(ReportStatus status, {ReportType? type}) =>
        ConditionReport.fromDraft(
          _completeDraft()..reportType = type ?? ReportType.issue,
        ).copyWith(status: status);

    test('only accepted / verified classified reports score a route', () {
      expect(withStatus(ReportStatus.accepted).isRouteScoringEligible, isTrue);
      expect(withStatus(ReportStatus.verified).isRouteScoringEligible, isTrue);
      expect(
        withStatus(ReportStatus.underReview).isRouteScoringEligible,
        isFalse,
      );
      expect(withStatus(ReportStatus.rejected).isRouteScoringEligible, isFalse);
    });

    test('status labels are stable', () {
      expect(ReportStatus.underReview.label, 'UNDER REVIEW');
      expect(ReportStatus.accepted.labelKey, 'accepted');
    });
  });

  group('submitted label', () {
    test('today shows the time', () {
      final now = DateTime.now();
      final label = submittedLabelFor(
        DateTime(now.year, now.month, now.day, 9, 5),
      );
      expect(label, 'Submitted today, 9:05 AM');
    });

    test('yesterday and older', () {
      final now = DateTime.now();
      expect(
        submittedLabelFor(now.subtract(const Duration(days: 1))),
        'Submitted yesterday',
      );
      expect(
        submittedLabelFor(now.subtract(const Duration(days: 5))),
        'Submitted 5 days ago',
      );
    });
  });
}
