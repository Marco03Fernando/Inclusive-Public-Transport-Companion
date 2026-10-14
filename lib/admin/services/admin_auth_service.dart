import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/state/app_state.dart';
import '../models/admin_exception.dart';
import '../models/admin_profile.dart';

/// Admin-role verification for the admin screens.
///
/// Signing in happens in the app's single login screen (`AuthService`).
/// This service independently re-checks that the signed-in account really
/// is an admin before any admin screen or admin data subscription starts.
///
/// How "is this user an admin?" works: `users/{uid}.role` must be
/// `"admin"`. Only the Firebase console can set that (the security rules
/// forbid users from writing their own role), so nobody can promote
/// themselves. The same field is what the Firestore/Storage security
/// rules check, so the client check here and the server-side enforcement
/// always agree.
class AdminAuthService {
  static const _usersCollection = 'users';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Emits whenever someone signs in or out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// The verified admin for [user], or null if [user] is not an admin
  /// (no user, an anonymous user, or a role other than admin).
  ///
  /// Throws [AdminException] if the role couldn't be checked at all
  /// (offline, or the rules refused to let the user read their own
  /// profile) — the caller still treats that as "not an admin".
  Future<AdminProfile?> verifyAdmin(User? user) async {
    if (user == null || user.isAnonymous) return null;

    try {
      if (await _isAdmin(user.uid)) {
        return AdminProfile(uid: user.uid, email: user.email);
      }
      return null;
    } on FirebaseException catch (e) {
      throw AdminException(
        e.code == 'permission-denied'
            ? 'Permission denied while checking admin access. Make sure the '
                  'latest Firestore security rules are deployed.'
            : 'Could not check admin access (${e.code}). Check your internet '
                  'connection and try again.',
      );
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<bool> _isAdmin(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();
    return AppRole.fromName(doc.data()?['role']) == AppRole.admin;
  }
}
