import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/state/app_state.dart';
import '../data/mock_data.dart';
import '../models/access_need.dart';
import '../models/contact.dart';
import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _contactsCol(String uid) => _userDoc(uid).collection('contacts');

  Future<void> createProfile({
    required String uid,
    required AppRole role,
    required String name,
    required String phone,
    required String dob,
    required List<AccessNeed> accessNeeds,
    required bool isAnonymous,
  }) {
    final profile = UserProfile(
      uid: uid,
      role: role,
      name: name,
      phone: phone,
      dob: dob,
      accessNeeds: accessNeeds,
      isAnonymous: isAnonymous,
    );
    return _userDoc(uid).set(profile.toMap());
  }

  Future<AppRole?> getRole(String uid) async {
    final snap = await _userDoc(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return data['role'] == 'volunteer' ? AppRole.volunteer : AppRole.passenger;
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return UserProfile.fromMap(uid, data, defaultAccessNeeds);
    });
  }

  Future<void> updateAccessNeeds(String uid, List<AccessNeed> accessNeeds) {
    return _userDoc(uid).update({
      'accessNeeds': accessNeeds.map((n) => {'id': n.id, 'checked': n.checked}).toList(),
    });
  }

  Stream<List<Contact>> watchContacts(String uid) {
    return _contactsCol(uid).orderBy('createdAt').snapshots().map(
          (snap) => snap.docs.map((doc) => Contact.fromMap(doc.id, doc.data())).toList(),
        );
  }

  Future<void> addContact(String uid, Contact contact) {
    return _contactsCol(uid).add({...contact.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateContact(String uid, Contact contact) {
    return _contactsCol(uid).doc(contact.id).update(contact.toMap());
  }

  Future<void> deleteContact(String uid, String contactId) {
    return _contactsCol(uid).doc(contactId).delete();
  }
}
