import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/public_condition_report.dart';
import '../models/report_exception.dart';
import 'condition_report_repository.dart';
import 'firebase_community_report_repository.dart';

/// Firestore + Firebase Storage implementation of
/// [ConditionReportRepository].
///
/// - Reports live in the `condition_reports` collection, one document per
///   report, with the document ID doubling as `reportId` inside the
///   document (handy for exports/admin tools that only have the map). The
///   admin module (`lib/admin/`) reads the same collection and shape.
/// - Photos are uploaded to Firebase Storage at
///   `condition_reports/{userId}/{reportId}.jpg` and only the resulting
///   download URL is stored in Firestore — the actual image bytes never
///   touch Firestore.
/// - The bucket is never hardcoded: [FirebaseStorage.instance] uses the
///   default app's `storageBucket` from `firebase_options.dart` /
///   `google-services.json`.
///
/// Every Firebase failure is rethrown as a [ReportException] whose
/// [ReportFailure] says which layer failed.
class FirebaseConditionReportRepository implements ConditionReportRepository {
  static const _collectionPath = 'condition_reports';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseConditionReportRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  static String _photoPath(String userId, String reportId) =>
      'condition_reports/$userId/$reportId.jpg';

  @override
  Future<ConditionReport> createReport(ConditionReport report) async {
    if (report.userId.isEmpty) {
      throw const ReportException(
        ReportFailure.auth,
        'Please sign in again to submit a report.',
      );
    }

    // 1. Generate the report ID up front so the photo path can use it.
    final docRef = _collection.doc();
    final reportId = docRef.id;
    _log(
      'createReport reportId=$reportId userId=${report.userId} '
      'photo=${report.photoPath ?? '(none)'}',
    );

    // 2–4. Optional photo: Storage ref → putFile → getDownloadURL.
    String? photoUrl;
    final localPhoto = report.photoPath;
    if (localPhoto != null && localPhoto.isNotEmpty) {
      photoUrl = await _uploadPhoto(
        userId: report.userId,
        reportId: reportId,
        localPath: localPhoto,
      );
    }

    // 5. Only now write the Firestore document.
    final now = DateTime.now();
    final toSave = report.copyWith(
      id: reportId,
      photoUrl: photoUrl,
      updatedAt: now,
    );
    try {
      await docRef.set(_toDocument(toSave, createdAt: now, updatedAt: now));
    } on FirebaseException catch (e) {
      // Don't leave an orphaned photo behind for a report that doesn't exist.
      if (photoUrl != null) {
        await _storage
            .ref(_photoPath(report.userId, reportId))
            .delete()
            .catchError((_) {});
      }
      throw _firestoreError(e, action: 'save your report');
    }
    _log('report $reportId saved to $_collectionPath');
    return toSave;
  }

  @override
  Future<List<ConditionReport>> getUserReports(String userId) async {
    try {
      final snapshot = await _userReportsQuery(userId).get();
      return _newestFirst(_parseAll(snapshot.docs));
    } on FirebaseException catch (e) {
      throw _firestoreError(e, action: 'load your reports');
    }
  }

  @override
  Stream<List<ConditionReport>> watchUserReports(String userId) {
    return _userReportsQuery(userId)
        .snapshots()
        .map((s) => _newestFirst(_parseAll(s.docs)))
        .handleError(
          (Object e) => throw e is FirebaseException
              ? _firestoreError(e, action: 'load your reports')
              : e,
        );
  }

  /// A user's own reports. Equality filter only, so Firestore's automatic
  /// single-field index is enough — no composite index has to be deployed
  /// for "My Reports" to load. Newest-first ordering is applied on the
  /// device by [_newestFirst] (a user's own list is small).
  Query<Map<String, dynamic>> _userReportsQuery(String userId) =>
      _collection.where('userId', isEqualTo: userId);

  static List<ConditionReport> _newestFirst(List<ConditionReport> reports) =>
      reports..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<ConditionReport> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminComment,
  }) async {
    final docRef = _collection.doc(reportId);
    final publicRef = _firestore
        .collection(PublicReportFields.collection)
        .doc(reportId);
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (adminComment != null) {
      updates['adminComment'] = adminComment;
    }

    try {
      // Same Community Reports handling as the admin review: accepting an
      // opted-in report publishes it, any other status takes it down — in
      // one transaction, so the public copy never disagrees with the report.
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw ReportException(
            ReportFailure.firestore,
            'That report no longer exists.',
            debugDetail: reportId,
          );
        }
        transaction.update(docRef, updates);
        final source = {...?snapshot.data(), 'status': status.name};
        if (isPublishableReport(source)) {
          transaction.set(
            publicRef,
            buildPublicReportProjection(source, status: status),
          );
        } else if (sharesWithCommunity(source)) {
          transaction.delete(publicRef);
        }
      });
      final updatedSnapshot = await docRef.get();
      if (!updatedSnapshot.exists) {
        throw ReportException(
          ReportFailure.firestore,
          'That report no longer exists.',
          debugDetail: reportId,
        );
      }
      return _fromDocument(updatedSnapshot);
    } on FirebaseException catch (e) {
      throw _firestoreError(e, action: 'update the report');
    }
  }

  @override
  Future<void> deleteReport(String reportId) async {
    try {
      // Look up the report first so we know which Storage object (if any)
      // to remove — deleting the Firestore doc doesn't touch Storage.
      final snapshot = await _collection.doc(reportId).get();
      final data = snapshot.data();
      final userId = data?['userId'] as String?;
      final photoUrl = data?['photoUrl'] as String?;
      if (userId != null &&
          userId.isNotEmpty &&
          photoUrl != null &&
          photoUrl.isNotEmpty) {
        try {
          await _storage.ref(_photoPath(userId, reportId)).delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') throw _storageError(e);
        }
      }
      // Retracting a report also takes down its Community Reports copy (if
      // it was published). One batch, so neither outlives the other; the
      // rules let the owner delete the public copy of their own report.
      final batch = _firestore.batch()..delete(_collection.doc(reportId));
      if (sharesWithCommunity(data)) {
        batch.delete(
          _firestore.collection(PublicReportFields.collection).doc(reportId),
        );
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _firestoreError(e, action: 'delete the report');
    }
  }

  Future<String> _uploadPhoto({
    required String userId,
    required String reportId,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw ReportException(
        ReportFailure.validation,
        'The selected photo is no longer available. Please choose it again.',
        debugDetail: localPath,
      );
    }

    final ref = _storage.ref(_photoPath(userId, reportId));
    // TEMP DEBUG (condition-report Storage 404): confirms which project and
    // bucket the upload actually targets. Remove once uploads are verified.
    _log(
      'Uploading image… project=${_storage.app.options.projectId} '
      'optionsBucket=${_storage.app.options.storageBucket} '
      'storageBucket=${_storage.bucket} path=${ref.fullPath}',
    );

    try {
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      _log('Image uploaded: ${ref.fullPath}');
      return url;
    } on FirebaseException catch (e) {
      throw _storageError(e);
    }
  }

  ReportException _storageError(FirebaseException e) {
    final bucket = _storage.bucket;
    _log('Storage error code=${e.code} bucket=$bucket message=${e.message}');
    final message = switch (e.code) {
      // A 404 while UPLOADING means the bucket itself doesn't exist, i.e.
      // Firebase Storage was never set up for this project.
      'object-not-found' || 'bucket-not-found' || 'project-not-found' =>
        'Photo storage is not set up for this app yet (bucket "$bucket"). '
            'Submit without a photo, or ask an admin to enable Firebase Storage.',
      'unauthorized' || 'unauthenticated' =>
        'You are not allowed to upload this photo. Please sign in again; if it keeps '
            'happening the Storage security rules need to be deployed.',
      'quota-exceeded' =>
        'Photo storage is full right now. Please try again later.',
      'retry-limit-exceeded' || 'canceled' =>
        'The photo upload did not finish. Check your connection and try again.',
      _ => 'Could not upload your photo. Please try again.',
    };
    return ReportException(
      ReportFailure.storage,
      message,
      debugDetail: '${e.code}: ${e.message}',
    );
  }

  ReportException _firestoreError(
    FirebaseException e, {
    required String action,
  }) {
    _log('Firestore error code=${e.code} message=${e.message}');
    final detail = '${e.code}: ${e.message}';
    return switch (e.code) {
      'failed-precondition' when (e.message ?? '').contains('index') =>
        ReportException(
          ReportFailure.missingIndex,
          'Could not $action: the database index for reports is still being set up.',
          debugDetail: detail,
        ),
      'permission-denied' => ReportException(
        ReportFailure.firestore,
        'Could not $action: permission denied. The Firestore security rules may need to be deployed.',
        debugDetail: detail,
      ),
      'unauthenticated' => ReportException(
        ReportFailure.auth,
        'Please sign in again to $action.',
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

  void _log(String message) {
    if (kDebugMode) debugPrint('[ConditionReports] $message');
  }

  /// Maps a [ConditionReport] onto the exact Firestore document shape:
  /// ```json
  /// {
  ///   "reportId": "abc123",
  ///   "userId": "uid_xyz",
  ///   "reportType": "issue",            // "positive" | "issue"
  ///   "routeNumber": "138A",            // as entered, for display
  ///   "routeId": "138A",                // normalized, for grouping
  ///   "subject": "bus",
  ///   "vehicleOrStationNumber": "NB-1234",
  ///   "conditionType": "brokenRamp",
  ///   "description": "Ramp is bent and won't lower.",
  ///   "locationName": "Current location attached",
  ///   "latitude": 6.9271,
  ///   "longitude": 79.8612,
  ///   "photoUrl": "https://firebasestorage.googleapis.com/...",
  ///   "status": "underReview",
  ///   "adminComment": null,
  ///   "shareWithCommunity": false,      // reporter's opt-in, set once
  ///   "publicDisplayName": null,        // profile name, or null = anonymous
  ///   "createdAt": Timestamp,
  ///   "updatedAt": Timestamp
  /// }
  /// ```
  Map<String, dynamic> _toDocument(
    ConditionReport report, {
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return {
      'reportId': report.id,
      'userId': report.userId,
      ReportFields.reportType: report.reportType.name,
      ReportFields.routeNumber: report.routeNumber,
      ReportFields.routeId: report.routeId,
      'subject': report.subject.name,
      'vehicleOrStationNumber': report.vehicleOrStationNumber,
      'conditionType': report.conditionType.name,
      'description': report.description,
      'locationName': report.location.label,
      'latitude': report.location.latitude,
      'longitude': report.location.longitude,
      'photoUrl': report.photoUrl,
      'status': report.status.name,
      'adminComment': report.adminComment,
      ReportFields.shareWithCommunity: report.shareWithCommunity,
      ReportFields.publicDisplayName: report.shareWithCommunity
          ? report.publicDisplayName
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Skips (and logs) documents that can't be parsed, so one malformed
  /// report never hides the rest of the user's list.
  List<ConditionReport> _parseAll(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final reports = <ConditionReport>[];
    for (final doc in docs) {
      try {
        reports.add(_fromDocument(doc));
      } catch (e) {
        _log('Skipping unreadable report ${doc.id}: $e');
      }
    }
    return reports;
  }

  ConditionReport _fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final updatedAtTimestamp = data['updatedAt'] as Timestamp?;

    return ConditionReport(
      id: (data['reportId'] as String?) ?? doc.id,
      userId: data['userId'] as String? ?? '',
      // Legacy documents have none of these: they read back as
      // unclassified / unassigned instead of being guessed.
      reportType: ReportType.parse(data[ReportFields.reportType]),
      routeNumber: data[ReportFields.routeNumber] as String? ?? '',
      routeId: data[ReportFields.routeId] as String? ?? '',
      subject: _enumOr(
        ReportSubject.values,
        data['subject'],
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
        data['conditionType'],
        ConditionType.other,
      ),
      description: data['description'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      status: _enumOr(
        ReportStatus.values,
        data['status'],
        ReportStatus.underReview,
      ),
      adminComment: data['adminComment'] as String?,
      shareWithCommunity: data[ReportFields.shareWithCommunity] == true,
      publicDisplayName: data[ReportFields.publicDisplayName] as String?,
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
      updatedAt: updatedAtTimestamp?.toDate(),
    );
  }

  static T _enumOr<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
