import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/access_need.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import 'app_state.dart';

/// The app's single auth state. Owns only the Firebase-facing identity bits
/// (current user, loading/error state). Role/accessNeeds still live on
/// [AppState] — every existing screen already reads those via
/// `context.watch<AppState>()` — this just hydrates [AppState] after a
/// successful sign-in/signup/guest-continue.
///
/// The role comes from `users/{uid}.role`; [AppRole.admin] routes to the
/// admin dashboard (see `widgets/auth_gate.dart` and the login screen).
class AuthState extends ChangeNotifier {
  AuthState({
    required this._appState,
    AuthService? authService,
    UserProfileService? userProfileService,
  })  : _authService = authService ?? AuthService(),
        _userProfileService = userProfileService ?? UserProfileService();

  final AppState _appState;
  final AuthService _authService;
  final UserProfileService _userProfileService;

  User? firebaseUser;
  bool loading = false;
  String? errorMessage;

  /// The signed-in user's real Firestore profile — kept live so every
  /// screen that shows the user's name/initials reads the same source
  /// instead of each re-querying (or worse, hardcoding a placeholder).
  UserProfile? profile;
  StreamSubscription<UserProfile?>? _profileSub;

  String? get uid => firebaseUser?.uid;

  /// True while a signed-in account has `role: "admin"`.
  bool get isAdmin => firebaseUser != null && _appState.role == AppRole.admin;

  void _watchProfile(String uid) {
    _profileSub?.cancel();
    profile = null;
    _profileSub = _userProfileService.watchProfile(uid).listen((p) {
      profile = p;
      notifyListeners();
    });
  }

  Future<AppRole?> hydrateFromExistingSession() async {
    final user = _authService.currentUser;
    firebaseUser = user;
    if (user == null) return null;
    final role = user.isAnonymous
        ? await _userProfileService.getRole(user.uid)
        : await _userProfileService.getOrCreateRole(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
          );
    if (role != null) _appState.setRole(role);
    _watchProfile(user.uid);
    notifyListeners();
    return role;
  }

  Future<bool> signIn(String email, String password) => _run(() async {
        final user = await _authService.signInWithEmail(email, password);
        final AppRole role;
        try {
          role = await _userProfileService.getOrCreateRole(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
          );
        } on FirebaseException {
          await _authService.signOut();
          throw AuthServiceException('Could not load your account. Check your connection and try again.');
        }
        firebaseUser = user;
        _appState.setRole(role);
        _watchProfile(user.uid);
      });

  Future<bool> continueAsGuest() => _run(() async {
        firebaseUser = await _authService.signInAnonymously();
        await _userProfileService.createProfile(
          uid: firebaseUser!.uid,
          role: AppRole.volunteer,
          name: 'Guest Volunteer',
          phone: '',
          dob: '',
          accessNeeds: const [],
          isAnonymous: true,
        );
        _appState.setRole(AppRole.volunteer);
        _watchProfile(firebaseUser!.uid);
      });

  /// Registers a passenger or volunteer. If the profile can't be written,
  /// the new Auth account is deleted again so the email address isn't left
  /// half-registered.
  Future<bool> signUpAndCreateProfile({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String dob,
    required AppRole role,
    required List<AccessNeed> accessNeeds,
  }) =>
      _run(() async {
        final user = await _authService.signUpWithEmail(email, password);
        try {
          await _userProfileService.createProfile(
            uid: user.uid,
            role: role,
            name: name.trim(),
            email: user.email ?? email.trim(),
            phone: phone,
            dob: dob,
            accessNeeds: accessNeeds,
            isAnonymous: false,
          );
        } catch (_) {
          await _authService.deleteCurrentUser();
          throw AuthServiceException('Could not create your profile. Check your connection and try again.');
        }
        await user.updateDisplayName(name.trim()).catchError((_) {});
        firebaseUser = user;
        _appState.setRole(role);
        _appState.setAccessNeeds(accessNeeds);
        _watchProfile(user.uid);
      });

  Future<void> signOut() async {
    await _authService.signOut();
    firebaseUser = null;
    await _profileSub?.cancel();
    _profileSub = null;
    profile = null;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthServiceException catch (e) {
      errorMessage = e.message;
      return false;
    } on FirebaseException catch (e) {
      errorMessage = e.message ?? e.code;
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
