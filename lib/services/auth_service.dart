import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

/// Email + password authentication and the `users/{uid}` profile.
///
/// One login / register system for everyone:
///  - [register] creates the Firebase Auth account AND the Firestore
///    profile `users/{uid}` with `role: "user"`, so normal users never
///    need to be created by hand in the Firebase console.
///  - [signIn] signs in and returns the profile, whose [UserProfile.role]
///    decides whether the app shows the user home or the admin dashboard.
///  - Admin accounts are created manually: a Firebase Auth user plus a
///    `users/{uid}` document with `role: "admin"`.
///
/// Everything above this (providers, services, repositories) only ever
/// reads [currentUserId] / the returned [UserProfile].
class AuthService {
  static const _usersCollection = 'users';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// The signed-in user's UID, or null if no one is signed in.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Emits whenever someone signs in or out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Returns the current UID, or throws if no one is signed in.
  ///
  /// The app only shows report screens after login, so this failing
  /// means the session expired underneath the screen.
  Future<String> ensureSignedIn() async {
    final uid = currentUserId;
    if (uid == null) {
      throw AuthServiceException('Please sign in again to continue.');
    }
    return uid;
  }

  /// Creates a normal user account and its `users/{uid}` profile.
  ///
  /// If the profile can't be written, the new Auth account is deleted
  /// again so the email address isn't left half-registered.
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_authMessage(e));
    }

    final user = credential.user;
    if (user == null) {
      throw AuthServiceException('Registration failed. Please try again.');
    }

    final profile = UserProfile(
      uid: user.uid,
      name: name.trim(),
      email: user.email ?? email.trim(),
      role: UserRole.user,
    );

    try {
      await _createProfile(profile);
      await user.updateDisplayName(profile.name);
    } on FirebaseException {
      await user.delete().catchError((_) {});
      await _auth.signOut();
      throw AuthServiceException(
        'Could not create your profile. Check your connection and try again.',
      );
    }

    return profile;
  }

  /// Signs in with email + password and returns the user's profile.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_authMessage(e));
    }

    final user = credential.user;
    if (user == null) {
      throw AuthServiceException('Sign-in failed. Please try again.');
    }

    try {
      return await fetchProfile(user);
    } on FirebaseException {
      await _auth.signOut();
      throw AuthServiceException(
        'Could not load your account. Check your connection and try again.',
      );
    }
  }

  /// Reads `users/{uid}`.
  ///
  /// An account without a profile (e.g. created in the console without a
  /// Firestore document) gets a normal `role: "user"` profile created for
  /// it — it can never become an admin this way.
  Future<UserProfile> fetchProfile(User user) async {
    final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
    final data = doc.data();
    if (data != null) return UserProfile.fromMap(user.uid, data);

    final email = user.email ?? '';
    final profile = UserProfile(
      uid: user.uid,
      name: user.displayName ?? email.split('@').first,
      email: email,
      role: UserRole.user,
    );
    await _createProfile(profile);
    return profile;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _createProfile(UserProfile profile) {
    return _firestore.collection(_usersCollection).doc(profile.uid).set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
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
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
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
