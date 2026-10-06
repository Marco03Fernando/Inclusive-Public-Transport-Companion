import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
/// instead of breaking the whole admin list.
class FirebaseAdminReportRepository implements AdminReportRepository {
  static const _collectionPath = 'condition_reports';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseAdminReportRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  @override
  Stream<List<ConditionReport>> watchAllReports() {
    // Single-field ordering only: no composite index required. Status
    // filtering is done on the client (see AdminReportsProvider) for the
    // same reason. Fine for thousands of reports; see the README notes on
    // pagination if the collection grows much larger.
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final reports = <ConditionReport>[];
      for (final doc in snapshot.docs) {
        final report = _fromDocument(doc);
        if (report != null) reports.add(report);
      }
      return reports;
    });
  }

  @override
  Future<void> reviewReport({
    required String reportId,
    required ReportStatus decision,
    required String adminComment,
  }) async {
    final docRef = _collection.doc(reportId);

    // A transaction, so two admins opening the same report can't silently
    // overwrite each other: the second one to save gets a clear message.
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw const AdminException('This report no longer exists.');
      }

      final current = _parseStatus(snapshot.data()?['status'] as String?);
      if (!current.isPending) {
        throw const AdminException(
          'This report has already been reviewed.',
        );
      }

      // Only these three fields are touched — the Firestore security
      // rules allow admins to change exactly these and nothing else.
      transaction.update(docRef, {
        'status': decision.name,
        'adminComment': adminComment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> deleteReport(String reportId) async {
    final docRef = _collection.doc(reportId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw const AdminException('This report no longer exists.');
    }

    // Photos live at condition_reports/{userId}/{reportId}.jpg (see
    // FirebaseConditionReportRepository._uploadPhoto). Deleting the
    // Firestore document doesn't touch Storage, so remove it explicitly.
    final data = snapshot.data();
    final userId = data?['userId'] as String?;
    final photoUrl = data?['photoUrl'] as String?;
    if (userId != null &&
        userId.isNotEmpty &&
        photoUrl != null &&
        photoUrl.isNotEmpty) {
      try {
        await _storage.ref('condition_reports/$userId/$reportId.jpg').delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
    }

    await docRef.delete();
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
          ConditionType.unsafe,
        ),
        description: data['description'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        status: _parseStatus(data['status'] as String?),
        adminComment: data['adminComment'] as String?,
        createdAt: createdAt?.toDate() ?? DateTime.now(),
        updatedAt: updatedAt?.toDate(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Existing documents store `status.name` ("underReview"). "under_review"
  /// is also accepted in case a document was ever edited by hand. Anything
  /// unknown is treated as still waiting for review, so it stays visible
  /// to the admin instead of vanishing.
  ReportStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'accepted':
        return ReportStatus.accepted;
      case 'rejected':
        return ReportStatus.rejected;
      case 'verified':
        return ReportStatus.verified;
      case 'underReview':
      case 'under_review':
        return ReportStatus.underReview;
      default:
        return ReportStatus.underReview;
    }
  }

  T _enumOr<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
