import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../models/admin_exception.dart';
import '../models/admin_profile.dart';
import '../services/admin_auth_service.dart';

/// Where the admin session currently stands.
enum AdminAuthStatus {
  /// Waiting for Firebase to report the auth state / verify the role.
  checking,

  /// The signed-in account is not a verified admin — no admin screens.
  unauthenticated,

  /// A verified admin is signed in — show the admin screens.
  authenticated,
}

/// Admin session state, used by `AdminGate` and to start/stop the live
/// reports subscription in `AdminReportsProvider`.
///
/// [status] is driven entirely by [AdminAuthService.authStateChanges], so it
/// reacts the same way whether the change came from the app's login
/// screen, a sign-out, or Firebase expiring the session.
class AdminAuthProvider extends ChangeNotifier {
  final AdminAuthService _service;
  StreamSubscription<User?>? _subscription;

  /// Bumped on every auth change so a slow role check for an old session
  /// can't overwrite the state of a newer one.
  int _generation = 0;

  AdminAuthProvider({required this._service}) {
    _subscription = _service.authStateChanges().listen(
      _onUserChanged,
      onError: (_) => _onAdminChanged(null),
    );
  }

  AdminAuthStatus _status = AdminAuthStatus.checking;
  AdminProfile? _profile;
  String? _error;
  User? _lastUser;

  AdminAuthStatus get status => _status;
  AdminProfile? get profile => _profile;
  bool get isAdmin => _status == AdminAuthStatus.authenticated;

  /// Set when the role couldn't be CHECKED (network / rules), as opposed
  /// to the account simply not being an admin. Access stays denied.
  String? get error => _error;

  Future<void> _onUserChanged(User? user) async {
    _lastUser = user;
    final generation = ++_generation;

    // Back to "checking" while the role is verified, so AdminGate shows a
    // spinner instead of briefly flashing "no access" right after login.
    if (user != null && _status != AdminAuthStatus.checking) {
      _status = AdminAuthStatus.checking;
      _profile = null;
      notifyListeners();
    }

    AdminProfile? profile;
    String? error;
    try {
      profile = await _service.verifyAdmin(user);
    } on AdminException catch (e) {
      error = e.message;
    }
    if (generation == _generation) _onAdminChanged(profile, error: error);
  }

  /// Re-checks the role of the signed-in account (after a failed check).
  Future<void> retry() {
    _status = AdminAuthStatus.checking;
    _error = null;
    notifyListeners();
    return _onUserChanged(_lastUser);
  }

  void _onAdminChanged(AdminProfile? profile, {String? error}) {
    _profile = profile;
    _error = error;
    _status = profile == null
        ? AdminAuthStatus.unauthenticated
        : AdminAuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signOut() => _service.signOut();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
