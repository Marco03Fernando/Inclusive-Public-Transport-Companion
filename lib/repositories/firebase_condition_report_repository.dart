import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/condition_report.dart';
import 'condition_report_repository.dart';

/// Firestore + Firebase Storage implementation of
/// [ConditionReportRepository].
///
/// - Reports live in the `condition_reports` collection, one document per
///   report, with the document ID doubling as `reportId` inside the
///   document (handy for exports/admin tools that only have the map).
/// - Photos are uploaded to Firebase Storage at
///   `condition_reports/{userId}/{reportId}.jpg` and only the resulting
///   download URL is stored in Firestore — the actual image bytes never
///   touch Firestore.
///
/// This is the only file in the app that imports `cloud_firestore` /
/// `firebase_storage`; [ConditionReport] itself stays backend-agnostic,
/// and all the Firestore ⇄ model mapping happens right here in
/// [_toDocument] / [_fromDocument].
class FirebaseConditionReportRepository implements ConditionReportRepository {
  static const _collectionPath = 'condition_reports';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseConditionReportRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

@override
Future<ConditionReport> createReport(ConditionReport report) async {
  try {
    print("===== START REPORT SUBMISSION =====");

    print("User ID: ${report.userId}");
    print("Photo path: ${report.photoPath}");

    if (report.userId.isEmpty) {
      throw ArgumentError(
          'Report must have a userId before it can be submitted.');
    }

    final docRef = _collection.doc();
    final reportId = docRef.id;

    print("Generated Report ID: $reportId");

    String? photoUrl;

    if (report.photoPath != null &&
        report.photoPath!.isNotEmpty) {

      print("Uploading image...");

      photoUrl = await _uploadPhoto(
        userId: report.userId,
        reportId: reportId,
        localPath: report.photoPath!,
      );

      print("Image uploaded: $photoUrl");
    }

    final now = DateTime.now();

    final toSave = report.copyWith(
      id: reportId,
      photoUrl: photoUrl,
      updatedAt: now,
    );

    print("Saving to Firestore...");

    await docRef.set(
      _toDocument(
        toSave,
        createdAt: now,
        updatedAt: now,
      ),
    );

    print("===== REPORT SAVED SUCCESSFULLY =====");

    return toSave;

  } catch (e, stack) {

    print("🔥 FIREBASE ERROR:");
    print(e);

    print(stack);

    rethrow;
  }
}

  @override
  Future<List<ConditionReport>> getUserReports(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(_fromDocument).toList();
  }

  @override
  Future<ConditionReport> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminComment,
  }) async {
    final docRef = _collection.doc(reportId);
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (adminComment != null) {
      updates['adminComment'] = adminComment;
    }

    await docRef.update(updates);

    final updatedSnapshot = await docRef.get();
    if (!updatedSnapshot.exists) {
      throw StateError('Report $reportId was not found in Firestore.');
    }
    return _fromDocument(updatedSnapshot);
  }

  @override
  Future<void> deleteReport(String reportId) async {
    // Look up the report first so we know which Storage object (if any)
    // to remove — deleting the Firestore doc doesn't touch Storage.
    final snapshot = await _collection.doc(reportId).get();
    if (snapshot.exists) {
      final data = snapshot.data();
      final userId = data?['userId'] as String?;
      if (userId != null && userId.isNotEmpty) {
        try {
          await _storage
              .ref('condition_reports/$userId/$reportId.jpg')
              .delete();
        } on FirebaseException catch (e) {
          // Photo may never have existed for this report — that's fine,
          // only rethrow unexpected failures.
          if (e.code != 'object-not-found') rethrow;
        }
      }
    }

    await _collection.doc(reportId).delete();
  }

  Future<String> _uploadPhoto({
    required String userId,
    required String reportId,
    required String localPath,
  }) async {
    final file = File(localPath);
    final ref = _storage.ref('condition_reports/$userId/$reportId.jpg');
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return uploadTask.ref.getDownloadURL();
  }

  /// Maps a [ConditionReport] onto the exact Firestore document shape:
  /// ```json
  /// {
  ///   "reportId": "abc123",
  ///   "userId": "uid_xyz",
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ConditionReport _fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final updatedAtTimestamp = data['updatedAt'] as Timestamp?;

    return ConditionReport(
      id: (data['reportId'] as String?) ?? doc.id,
      userId: data['userId'] as String? ?? '',
      subject: ReportSubject.values.byName(data['subject'] as String? ?? 'other'),
      vehicleOrStationNumber: data['vehicleOrStationNumber'] as String? ?? '',
      location: ReportLocation(
        label: data['locationName'] as String? ?? '',
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
      ),
      conditionType:
          ConditionType.values.byName(data['conditionType'] as String? ?? 'unsafe'),
      description: data['description'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      status: ReportStatus.values.byName(data['status'] as String? ?? 'underReview'),
      adminComment: data['adminComment'] as String?,
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
      updatedAt: updatedAtTimestamp?.toDate(),
    );
  }
}
