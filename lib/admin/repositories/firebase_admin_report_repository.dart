import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../models/condition_report.dart';
import '../models/admin_exception.dart';
import '../models/report_filter.dart';
import 'admin_report_repository.dart';

/// Firestore implementation of [AdminReportRepository].
///
/// Reads and updates the SAME `condition_reports` collection the user
/// side writes to — no new collection, no schema change. The Firestore ⇄
/// model mapping mirrors `FirebaseConditionReportRepository._fromDocument`
/// (flat `locationName` / `latitude` / `longitude`, `vehicleOrStationNumber`
/// etc.), except that it is TOLERANT: one malformed document is skipped
/// (and counted) instead of breaking the whole admin list.
///
/// Writes only ever touch `status`, `adminComment` and `updatedAt` — the
/// exact fields `firestore.rules` lets an admin change.
class FirebaseAdminReportRepository implements AdminReportRepository {
  static const _collectionPath = 'condition_reports';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseAdminReportRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  @override
  Stream<AdminReportsSnapshot> watchAllReports() {
    // Single-field ordering only: no composite index required. Status
    // filtering is done on the client (see AdminReportsProvider) for the
    // same reason.
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final reports = <ConditionReport>[];
          var skipped = 0;
          for (final doc in snapshot.docs) {
            final report = _fromDocument(doc);
            if (report == null) {
              skipped++;
            } else {
              reports.add(report);
            }
          }
          return (reports: reports, skipped: skipped);
        })
        .handleError(
          (Object e) => throw e is FirebaseException
              ? _mapError(e, action: 'load reports')
              : e,
        );
  }

  @override
  Future<void> reviewReport({
    required String reportId,
    required ReportStatus decision,
    required String adminComment,
    required ReportStatus expectedStatus,
  }) async {
    final docRef = _collection.doc(reportId);

    // A transaction, so two admins on the same report can't silently
    // overwrite each other: the second one to save gets a clear message.
    await _guard(
      action: 'save your decision',
      () => _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw const AdminException('This report no longer exists.');
        }

        final current = parseReportStatus(snapshot.data()?['status']);
        if (current != expectedStatus) {
          throw const AdminException(
            'This report was just updated by someone else. '
            'Please check its new status and try again.',
          );
        }

        transaction.update(docRef, {
          'status': decision.name,
          'adminComment': adminComment,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }),
    );
  }

  @override
  Future<void> updateComment({
    required String reportId,
    required String adminComment,
  }) {
    return _guard(
      action: 'save the comment',
      () => _collection.doc(reportId).update({
        'adminComment': adminComment,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<void> deleteReport(String reportId) {
    return _guard(action: 'delete the report', () async {
      final docRef = _collection.doc(reportId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        throw const AdminException('This report no longer exists.');
      }

      // Photos live at condition_reports/{userId}/{reportId}.jpg (see
      // FirebaseConditionReportRepository). Deleting the Firestore
      // document doesn't touch Storage, so remove it explicitly.
      final data = snapshot.data();
      final userId = data?['userId'] as String?;
      final photoUrl = data?['photoUrl'] as String?;
      if (userId != null &&
          userId.isNotEmpty &&
          photoUrl != null &&
          photoUrl.isNotEmpty) {
        try {
          await _storage
              .ref('condition_reports/$userId/$reportId.jpg')
              .delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
        }
      }

      await docRef.delete();
    });
  }

  /// Runs [body], turning Firebase failures into an [AdminException] whose
  /// message says whether it was a permission, network or missing-report
  /// problem.
  Future<void> _guard(
    Future<void> Function() body, {
    required String action,
  }) async {
    try {
      await body();
    } on AdminException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapError(e, action: action);
    }
  }

  AdminException _mapError(FirebaseException e, {required String action}) {
    if (kDebugMode) {
      debugPrint(
        '[Admin] ${e.plugin}/${e.code} while trying to $action: '
        '${e.message}',
      );
    }
    switch (e.code) {
      case 'permission-denied':
      case 'unauthorized':
      case 'unauthenticated':
        return AdminException(
          'Permission denied: could not $action. Make sure this account has '
          'role "admin" in users/{uid} and the latest security rules are '
          'deployed.',
        );
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
      case 'retry-limit-exceeded':
        return AdminException(
          'Network problem: could not $action. Check your internet '
          'connection and try again.',
        );
      case 'not-found':
        return const AdminException('This report no longer exists.');
      default:
        return AdminException(
          'Could not $action (${e.code}). Please try again.',
        );
    }
  }

  /// Returns null (skips the document) if it can't be parsed.
  ConditionReport? _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data();

      final createdAt = data['createdAt'] as Timestamp?;
      final updatedAt = data['updatedAt'] as Timestamp?;

      return ConditionReport(
        id: (data['reportId'] as String?) ?? doc.id,
        userId: data['userId'] as String? ?? '',
        subject: _enumOr(
          ReportSubject.values,
          data['subject'] as String?,
          ReportSubject.other,
        ),
        vehicleOrStationNumber: data['vehicleOrStationNumber'] as String? ?? '',
        location: ReportLocation(
          label: data['locationName'] as String? ?? '',
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
        ),
        conditionType: _enumOr(
          ConditionType.values,
          data['conditionType'] as String?,
          ConditionType.other,
        ),
        description: data['description'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        status: parseReportStatus(data['status']),
        adminComment: data['adminComment'] as String?,
        createdAt: createdAt?.toDate() ?? DateTime.now(),
        updatedAt: updatedAt?.toDate(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Admin] Skipping malformed report ${doc.id}: $e');
      }
      return null;
    }
  }

  T _enumOr<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
