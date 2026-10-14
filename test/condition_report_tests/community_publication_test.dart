// Privacy of the community (public) copy of a report, built and parsed on
// the client (lib/repositories/firebase_community_report_repository.dart).
// The matching server-side enforcement lives in firestore.rules and is
// covered separately by firestore_rules_test/ (Firestore emulator).
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/models/public_condition_report.dart';
import 'package:colombo_pal/repositories/firebase_community_report_repository.dart';

/// A private `condition_reports` document as the app writes it.
Map<String, dynamic> privateDoc({
  String status = 'accepted',
  bool? share = true,
  String? publicName,
  String reportType = 'issue',
}) => {
  'reportId': 'r1',
  'userId': 'secret-uid',
  'reportType': reportType,
  'routeNumber': '138A',
  'routeId': '138A',
  'subject': 'bus',
  'vehicleOrStationNumber': 'NB-1234',
  'conditionType': 'brokenRamp',
  'description': 'Ramp is bent.',
  'locationName': 'Current location attached',
  'latitude': 6.927149,
  'longitude': 79.861244,
  'photoUrl': 'https://example.test/p.jpg',
  'status': status,
  'adminComment': 'internal note',
  'shareWithCommunity': ?share,
  'publicDisplayName': publicName,
  'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
  'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 2)),
};

void main() {
  group('who may be published', () {
    test('accepted (or legacy verified) + opted in + classified', () {
      expect(isPublishableReport(privateDoc()), isTrue);
      expect(isPublishableReport(privateDoc(status: 'verified')), isTrue);
    });

    test('never under review or rejected', () {
      expect(isPublishableReport(privateDoc(status: 'underReview')), isFalse);
      expect(isPublishableReport(privateDoc(status: 'rejected')), isFalse);
    });

    test('never without explicit consent (incl. legacy reports)', () {
      expect(isPublishableReport(privateDoc(share: false)), isFalse);
      expect(isPublishableReport(privateDoc(share: null)), isFalse);
      expect(sharesWithCommunity(privateDoc(share: null)), isFalse);
      expect(sharesWithCommunity(null), isFalse);
    });

    test('never unclassified', () {
      expect(isPublishableReport(privateDoc(reportType: 'other')), isFalse);
    });
  });

  group('public copy contents', () {
    final copy = buildPublicReportProjection(
      privateDoc(publicName: 'Kamala'),
      status: ReportStatus.accepted,
    );

    test('only whitelisted fields — no private or internal data', () {
      expect(copy.keys.toSet(), {
        'reportType',
        'routeNumber',
        'routeId',
        'subject',
        'vehicleOrStationNumber',
        'conditionType',
        'description',
        'locationName',
        'latitude',
        'longitude',
        'photoUrl',
        'contributorName',
        'status',
        'createdAt',
        'publishedAt',
      });
      for (final privateKey in [
        'userId',
        'reportId',
        'adminComment',
        'updatedAt',
        'shareWithCommunity',
        'publicDisplayName',
      ]) {
        expect(copy.containsKey(privateKey), isFalse, reason: privateKey);
      }
    });

    test('coordinates are rounded to about 100 m', () {
      expect(copy['latitude'], 6.927);
      expect(copy['longitude'], 79.861);
    });

    test('contributor is the chosen public name, or anonymous', () {
      expect(copy['contributorName'], 'Kamala');
      final anonymous = buildPublicReportProjection(
        privateDoc(),
        status: ReportStatus.accepted,
      );
      expect(anonymous['contributorName'], isNull);
    });
  });

  group('reading the public copy', () {
    Map<String, dynamic> publicDoc({String status = 'accepted'}) => {
      ...buildPublicReportProjection(
        privateDoc(),
        status: ReportStatus.accepted,
      )..remove('publishedAt'),
      'status': status,
    };

    test('a valid copy parses for the feed', () {
      final report = publicReportFromDocument('r1', publicDoc());
      expect(report, isNotNull);
      expect(report!.headline, 'Bus NB-1234 · Broken ramp');
      expect(report.contributorName, isNull);
      expect(report.routeLabel, '138A');
      expect(report.locationLabel, 'Near 6.927, 79.861');
    });

    test('anything not accepted is skipped, never shown', () {
      expect(
        publicReportFromDocument('r1', publicDoc(status: 'underReview')),
        isNull,
      );
      expect(
        publicReportFromDocument('r1', publicDoc(status: 'rejected')),
        isNull,
      );
    });

    test('malformed documents are skipped', () {
      expect(
        publicReportFromDocument('r1', publicDoc()..remove('createdAt')),
        isNull,
      );
      expect(
        publicReportFromDocument('r1', publicDoc()..['reportType'] = 'x'),
        isNull,
      );
    });
  });
}
