import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Where the app-wide session currently stands.
enum AuthStatus {
  /// Waiting for Firebase to report the initial auth state / the profile.
  checking,

  /// No one signed in — show the login / register screen.
  unauthenticated,

  /// Signed in with a loaded [UserProfile] — route by its role.
  authenticated,
}

/// App-wide login state: who is signed in and what their role is.
///
/// Driven by [AuthService.authStateChanges], so it reacts the same way to
/// the login form, the register form, a sign-out from any screen (user or
/// admin), and Firebase expiring the session.
class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  StreamSubscription<User?>? _subscription;

  /// Bumped on every auth change so a slow profile read for an old
  /// session can't overwrite the state of a newer one.
  int _generation = 0;

  AuthProvider({required AuthService service}) : _service = service {
    _subscription = _service.authStateChanges().listen(
      _onUserChanged,
      onError: (_) => _setSignedOut(),
    );
  }

  AuthStatus _status = AuthStatus.checking;
  UserProfile? _profile;
  bool _isSubmitting = false;
  String? _error;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isSubmitting => _isSubmitting;

  /// User-facing message from the last failed sign-in / registration.
  String? get error => _error;

  Future<void> _onUserChanged(User? user) async {
    final generation = ++_generation;

    if (user == null) {
      _setSignedOut();
      return;
    }

    // Sessions from the old anonymous-only version of the app have no
    // email/password account — end them so the login screen appears.
    if (user.isAnonymous) {
      await _service.signOut();
      return;
    }

    // signIn / register load the profile themselves.
    if (_isSubmitting) return;

    _status = AuthStatus.checking;
    notifyListeners();

    try {
      final profile = await _service.fetchProfile(user);
      if (generation != _generation) return;
      _profile = profile;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      if (generation != _generation) return;
      _error = 'Could not load your account. Please sign in again.';
      await _service.signOut();
    }
  }

  void _setSignedOut() {
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Returns true on success (the AuthGate then routes by role by
  /// itself); on failure [error] is set and this returns false.
  Future<bool> signIn({required String email, required String password}) {
    return _submit(() => _service.signIn(email: email, password: password));
  }

  /// Registers a normal user (`role: "user"`).
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _submit(
      () => _service.register(name: name, email: email, password: password),
    );
  }

  Future<bool> _submit(Future<UserProfile> Function() action) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await action();
      _status = AuthStatus.authenticated;
      return true;
    } on AuthServiceException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() => _service.signOut();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
