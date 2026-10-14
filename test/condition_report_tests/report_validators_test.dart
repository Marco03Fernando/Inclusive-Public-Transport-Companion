// Report form validators (lib/utils/validators.dart): required fields,
// empty / whitespace input, boundaries and the exact user-facing messages.
//
// Partly moved from test/roles_and_reports_test.dart.
import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/models/report_model.dart';
import 'package:colombo_pal/utils/validators.dart';

void main() {
  group('report type (required)', () {
    test('missing or unclassified is rejected', () {
      expect(ReportValidators.reportType(null), 'Choose a report type.');
      expect(
        ReportValidators.reportType(ReportType.unknown),
        'Choose a report type.',
      );
    });

    test('both selectable types pass', () {
      for (final type in ReportType.selectable) {
        expect(ReportValidators.reportType(type), isNull);
      }
    });
  });

  group('bus route number (required)', () {
    test('delegates to BusRoute.validate', () {
      expect(ReportValidators.routeNumber('138A'), isNull);
      expect(
        ReportValidators.routeNumber(''),
        'Enter the bus route number (e.g. 138 or 138A).',
      );
      expect(
        ReportValidators.routeNumber('138 & 177'),
        'Use only letters, numbers, "-" or "/" (e.g. 138 or 138A).',
      );
      // A road name is not a route number.
      expect(
        ReportValidators.routeNumber('Galle Road'),
        'A bus route number must include a number (e.g. 138).',
      );
    });

    test('12 characters is the maximum after normalising', () {
      expect(ReportValidators.routeNumber('123456789012'), isNull);
      expect(ReportValidators.routeNumber('1234567890123'), isNotNull);
      // Inner spaces are removed before the length check.
      expect(ReportValidators.routeNumber('1 2 3 4 5 6 7 8 9 0 1 2'), isNull);
    });
  });

  group('subject and condition type (required)', () {
    test('null is rejected with a clear prompt', () {
      expect(ReportValidators.subject(null), 'Choose what you are reporting.');
      expect(ReportValidators.conditionType(null), 'Choose a condition type.');
    });

    test('every value is accepted', () {
      for (final s in ReportSubject.values) {
        expect(ReportValidators.subject(s), isNull);
      }
      for (final c in ConditionType.values) {
        expect(ReportValidators.conditionType(c), isNull);
      }
    });
  });

  group('vehicle / station number', () {
    test('required for bus, station and rest area', () {
      for (final s in [
        ReportSubject.bus,
        ReportSubject.station,
        ReportSubject.restArea,
      ]) {
        expect(
          ReportValidators.vehicleOrStationNumber('  ', s),
          'Enter a vehicle or station number.',
          reason: '$s',
        );
      }
    });

    test('optional when the subject is "Other"', () {
      expect(
        ReportValidators.vehicleOrStationNumber('', ReportSubject.other),
        isNull,
      );
      expect(
        ReportValidators.vehicleOrStationNumber(null, ReportSubject.other),
        isNull,
      );
    });

    test('a single character is flagged as too short', () {
      expect(
        ReportValidators.vehicleOrStationNumber('N', ReportSubject.bus),
        'That number looks too short — please check it.',
      );
      expect(
        ReportValidators.vehicleOrStationNumber('NB', ReportSubject.bus),
        isNull,
      );
    });
  });

  group('location (required)', () {
    test('empty or blank asks for GPS', () {
      expect(
        ReportValidators.location(null),
        'Add a location using the GPS button.',
      );
      expect(
        ReportValidators.location('   '),
        'Add a location using the GPS button.',
      );
      expect(ReportValidators.location('Current location attached'), isNull);
    });
  });

  group('description (required, at least 10 characters)', () {
    test('empty / whitespace', () {
      expect(ReportValidators.description(''), 'Please describe what you saw.');
      expect(
        ReportValidators.description('     '),
        'Please describe what you saw.',
      );
    });

    test('boundary at 10 trimmed characters', () {
      expect(
        ReportValidators.description('too short'),
        'Please add a few more details (at least 10 characters).',
      );
      // 9 characters padded with spaces is still too short.
      expect(ReportValidators.description('   123456789   '), isNotNull);
      expect(ReportValidators.description('1234567890'), isNull);
    });

    test('non-Latin (Sinhala) descriptions are accepted', () {
      expect(
        ReportValidators.description('රැම්පය කැඩී ඇති අතර පහත් නොවේ'),
        isNull,
      );
    });
  });
}
