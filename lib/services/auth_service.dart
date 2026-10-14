import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication only — the `users/{uid}` profile (and its role)
/// lives in `UserProfileService`, and `AuthState` ties the two together.
///
/// Every failure surfaces as an [AuthServiceException] whose message can be
/// shown to the user as-is.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  /// The signed-in user's UID, or null if no one is signed in.
  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Returns the current UID, or throws if no one is signed in.
  ///
  /// Report screens are only reachable after login, so this failing means
  /// the session expired underneath the screen.
  Future<String> ensureSignedIn() async {
    final uid = currentUserId;
    if (uid == null) {
      throw AuthServiceException('Please sign in again to continue.');
    }
    return uid;
  }

  Future<User> signUpWithEmail(String email, String password) => _guard(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<User> signInWithEmail(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<User> signInAnonymously() => _guard(_auth.signInAnonymously);

  /// Undoes a half-finished registration (Auth account created but its
  /// profile couldn't be written) so the email address isn't left taken.
  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      // Best effort — the sign-out below still ends the session.
    }
    await _auth.signOut();
  }

  Future<void> signOut() => _auth.signOut();

  Future<User> _guard(Future<UserCredential> Function() action) async {
    final UserCredential credential;
    try {
      credential = await action();
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_authMessage(e));
    }
    final user = credential.user;
    if (user == null) {
      throw AuthServiceException('Sign-in failed. Please try again.');
    }
    return user;
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message);

  @override
  String toString() => message;
}
