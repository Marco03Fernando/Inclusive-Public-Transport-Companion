import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/assistance_request.dart';

class AssistanceRequestService {
  AssistanceRequestService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('assistance_requests');

  Future<String> createRequest(AssistanceRequest request) async {
    final doc = await _col.add(request.toCreateMap());
    return doc.id;
  }

  Stream<List<AssistanceRequest>> watchRequestsForPassenger(String passengerUid) {
    return _col
        .where('passengerUid', isEqualTo: passengerUid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AssistanceRequest.fromMap(d.id, d.data())).toList());
  }

  Stream<List<AssistanceRequest>> watchOpenRequests() {
    return _col
        .where('status', isEqualTo: AssistanceStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AssistanceRequest.fromMap(d.id, d.data())).toList());
  }

  Stream<List<AssistanceRequest>> watchAcceptedByVolunteer(String volunteerUid) {
    return _col
        .where('volunteerUid', isEqualTo: volunteerUid)
        .where('status', isEqualTo: AssistanceStatus.accepted.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AssistanceRequest.fromMap(d.id, d.data())).toList());
  }

  /// Transaction guards against two volunteers accepting the same request.
  Future<bool> acceptRequest(String requestId, String volunteerUid, String volunteerName) {
    final doc = _col.doc(requestId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(doc);
      if (snap.data()?['status'] != AssistanceStatus.pending.name) return false;
      tx.update(doc, {
        'status': AssistanceStatus.accepted.name,
        'volunteerUid': volunteerUid,
        'volunteerName': volunteerName,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> completeRequest(String requestId) {
    return _col.doc(requestId).update({
      'status': AssistanceStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelRequest(String requestId) {
    return _col.doc(requestId).update({'status': AssistanceStatus.cancelled.name});
  }
}
