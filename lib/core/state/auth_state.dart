import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/access_need.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import 'app_state.dart';

/// Owns only the Firebase-facing identity bits (current user, loading/error
/// state). Role/accessNeeds still live on [AppState] — every existing screen
/// already reads those via `context.watch<AppState>()` — this just hydrates
/// [AppState] after a successful sign-in/signup/guest-continue.
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
    final role = await _userProfileService.getRole(user.uid);
    if (role != null) _appState.setRole(role);
    _watchProfile(user.uid);
    return role;
  }

  Future<bool> signIn(String email, String password) => _run(() async {
        firebaseUser = await _authService.signInWithEmail(email, password);
        final role = await _userProfileService.getRole(firebaseUser!.uid) ?? AppRole.passenger;
        _appState.setRole(role);
        _watchProfile(firebaseUser!.uid);
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
        firebaseUser = await _authService.signUpWithEmail(email, password);
        await _userProfileService.createProfile(
          uid: firebaseUser!.uid,
          role: role,
          name: name,
          phone: phone,
          dob: dob,
          accessNeeds: accessNeeds,
          isAnonymous: false,
        );
        _appState.setRole(role);
        _appState.setAccessNeeds(accessNeeds);
        _watchProfile(firebaseUser!.uid);
      });

  Future<void> signOut() async {
    await _authService.signOut();
    firebaseUser = null;
    await _profileSub?.cancel();
    _profileSub = null;
    profile = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? e.code;
      return false;
    } catch (e) {
      errorMessage = e.toString();
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

