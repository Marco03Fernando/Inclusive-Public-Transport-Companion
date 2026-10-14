import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'services/firebase_bootstrap.dart';

/// Colombo Pal — single entry point for passengers, volunteers AND admins.
///
/// Sign-in routes by `users/{uid}.role` (see `widgets/auth_gate.dart` and
/// `Routes.homeFor`): passenger → home, volunteer → volunteer home,
/// admin → admin dashboard (`lib/admin/`).
///
/// Startup: the native splash (static icon, `flutter_native_splash` config
/// in pubspec.yaml) stays up until the Flutter startup splash has its logo
/// decoded (`widgets/startup_splash.dart`); `AuthGate` then waits for
/// Firebase + the saved session behind that splash.
///
/// Firebase console setup:
///  1. Authentication → enable Email/Password and Anonymous.
///  2. Deploy `firestore.rules` and `storage.rules`
///     (`firebase deploy --only firestore:rules,storage`) — they are what
///     actually stop normal users from reading or changing admin data.
///  3. For each admin: create the account in Authentication, then set
///     `role: "admin"` on its `users/{uid}` document.
void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  // Start Firebase alongside the first frame. Errors surface (with a retry)
  // where AuthGate awaits it, so nothing is lost by ignoring them here.
  FirebaseBootstrap.ensureInitialized().ignore();
  runApp(const ColomboPalApp());
}
