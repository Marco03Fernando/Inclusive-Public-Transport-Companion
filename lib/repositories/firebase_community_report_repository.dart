import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/public_condition_report.dart';
import '../models/report_exception.dart';
import 'community_report_repository.dart';

/// Firestore implementation of [CommunityReportRepository].
///
/// One ordered query (`createdAt` desc, single-field index — no composite
/// index needed). Subject / type filtering happens on the client over the
/// loaded list, so changing a filter costs no extra reads.
class FirebaseCommunityReportRepository implements CommunityReportRepository {
  FirebaseCommunityReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(PublicReportFields.collection);

  @override
  Stream<List<PublicConditionReport>> watchPublishedReports({
    required int limit,
  }) {
    return _collection
        .orderBy(PublicReportFields.createdAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final reports = <PublicConditionReport>[];
          for (final doc in snapshot.docs) {
            final report = publicReportFromDocument(doc.id, doc.data());
            if (report != null) reports.add(report);
          }
          return reports;
        })
        .handleError(
          (Object e) => throw e is FirebaseException
              ? _error(e, action: 'load community reports')
              : e,
        );
  }

  @override
  Stream<PublicConditionReport?> watchReport(String reportId) {
    return _collection
        .doc(reportId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? publicReportFromDocument(doc.id, doc.data()!) : null,
        )
        .handleError(
          (Object e) => throw e is FirebaseException
              ? _error(e, action: 'load this report')
              : e,
        );
  }

  ReportException _error(FirebaseException e, {required String action}) {
    if (kDebugMode) {
      debugPrint('[CommunityReports] ${e.code} while trying to $action');
    }
    final detail = '${e.code}: ${e.message}';
    return switch (e.code) {
      'permission-denied' => ReportException(
        ReportFailure.firestore,
        'Could not $action: permission denied. Please sign in again; if it '
        'keeps happening the Firestore security rules need to be deployed.',
        debugDetail: detail,
      ),
      'unavailable' || 'deadline-exceeded' => ReportException(
        ReportFailure.network,
        'Could not $action. Check your internet connection and try again.',
        debugDetail: detail,
      ),
      _ => ReportException(
        ReportFailure.firestore,
        'Could not $action. Please try again.',
        debugDetail: detail,
      ),
    };
  }
}

/// Parses a `public_condition_reports` document. Returns null (the item is
/// skipped) when it is malformed or not an accepted report — the feed
/// never shows anything it can't classify as verified.
PublicConditionReport? publicReportFromDocument(
  String id,
  Map<String, dynamic> data,
) {
  final status = _enumOr(
    ReportStatus.values,
    data[PublicReportFields.status],
    null,
  );
  final reportType = ReportType.parse(data[PublicReportFields.reportType]);
  final createdAt = data[PublicReportFields.createdAt];
  if (status == null ||
      !(status == ReportStatus.accepted || status == ReportStatus.verified) ||
      !reportType.isClassified ||
      createdAt is! Timestamp) {
    if (kDebugMode) debugPrint('[CommunityReports] Skipping report $id');
    return null;
  }
  final name = data[PublicReportFields.contributorName];
  return PublicConditionReport(
    id: id,
    reportType: reportType,
    routeNumber: data[PublicReportFields.routeNumber] as String? ?? '',
    subject:
        _enumOr(ReportSubject.values, data[PublicReportFields.subject], null) ??
        ReportSubject.other,
    vehicleOrStationNumber:
        data[PublicReportFields.vehicleOrStationNumber] as String? ?? '',
    conditionType:
        _enumOr(
          ConditionType.values,
          data[PublicReportFields.conditionType],
          null,
        ) ??
        ConditionType.other,
    description: data[PublicReportFields.description] as String? ?? '',
    locationName: data[PublicReportFields.locationName] as String? ?? '',
    latitude: (data[PublicReportFields.latitude] as num?)?.toDouble(),
    longitude: (data[PublicReportFields.longitude] as num?)?.toDouble(),
    photoUrl: data[PublicReportFields.photoUrl] as String?,
    contributorName: name is String && name.trim().isNotEmpty ? name : null,
    status: status,
    createdAt: createdAt.toDate(),
  );
}

/// Whether the reporter opted in to Community Reports — i.e. whether the
/// report can have a public copy at all. Consent is fixed at submission,
/// so reports without it never need their (non-existent) copy cleaned up.
bool sharesWithCommunity(Map<String, dynamic>? source) =>
    source?[ReportFields.shareWithCommunity] == true;

/// Whether a private `condition_reports` document may be published: an
/// admin accepted it, its reporter opted in, and it is classified. Mirrors
/// `publishable()` in `firestore.rules`, which is what actually enforces it.
bool isPublishableReport(Map<String, dynamic> source) {
  final status = source[ReportFields.status];
  return (status == ReportStatus.accepted.name ||
          status == ReportStatus.verified.name) &&
      source[ReportFields.shareWithCommunity] == true &&
      ReportType.parse(source[ReportFields.reportType]).isClassified;
}

/// Builds the whitelisted public copy of a private report document. Every
/// value is copied verbatim from [source] (the rules check that), except:
/// coordinates are rounded to ≈100 m, the contributor name is only the
/// reporter's chosen public name, and [status] is the status the report
/// has once the surrounding write completes.
Map<String, dynamic> buildPublicReportProjection(
  Map<String, dynamic> source, {
  required ReportStatus status,
}) {
  return {
    PublicReportFields.reportType: source[ReportFields.reportType],
    PublicReportFields.routeNumber: source[ReportFields.routeNumber] ?? '',
    PublicReportFields.routeId: source[ReportFields.routeId] ?? '',
    PublicReportFields.subject: source['subject'],
    PublicReportFields.vehicleOrStationNumber:
        source['vehicleOrStationNumber'] ?? '',
    PublicReportFields.conditionType: source['conditionType'],
    PublicReportFields.description: source['description'] ?? '',
    PublicReportFields.locationName: source['locationName'] ?? '',
    PublicReportFields.latitude: _approximate(source['latitude']),
    PublicReportFields.longitude: _approximate(source['longitude']),
    PublicReportFields.photoUrl: source['photoUrl'],
    PublicReportFields.contributorName: source[ReportFields.publicDisplayName],
    PublicReportFields.status: status.name,
    PublicReportFields.createdAt: source['createdAt'],
    PublicReportFields.publishedAt: FieldValue.serverTimestamp(),
  };
}

/// 3 decimal places ≈ 110 m: enough to find the stop, not the person.
double? _approximate(Object? value) =>
    value is num ? (value * 1000).round() / 1000 : null;

T? _enumOr<T extends Enum>(List<T> values, Object? name, T? fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
