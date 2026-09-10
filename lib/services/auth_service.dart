import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around `firebase_auth`.
///
/// The Condition Reporting screens don't include a sign-in flow, so this
/// defaults to anonymous auth: every device gets a stable Firebase UID
/// the first time it submits a report, which is enough to scope
/// `getUserReports()` and satisfy Firestore/Storage security rules
/// written against `request.auth.uid`. Swap [ensureSignedIn] for a real
/// sign-in flow later without touching any other layer — everything
/// above this (provider, service, repository) only ever readqs
/// [currentUserId].
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// The signed-in user's UID, or null if no one is signed in yet.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Returns the current UID, signing in anonymously first if needed.
  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;

    try {
      final credential = await _auth.signInAnonymously();
      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthServiceException('Sign-in succeeded but no user was returned.');
      }
      return uid;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(e.message ?? 'Could not sign in. Please try again.');
    }
  }
}

class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message);

  @override
  String toString() => message;
}
