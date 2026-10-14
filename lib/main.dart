import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Colombo Pal — single entry point for passengers, volunteers AND admins.
///
/// Sign-in routes by `users/{uid}.role` (see `widgets/auth_gate.dart` and
/// `Routes.homeFor`): passenger → home, volunteer → volunteer home,
/// admin → admin dashboard (`lib/admin/`).
///
/// Firebase console setup:
///  1. Authentication → enable Email/Password and Anonymous.
///  2. Deploy `firestore.rules` and `storage.rules`
///     (`firebase deploy --only firestore:rules,storage`) — they are what
///     actually stop normal users from reading or changing admin data.
///  3. For each admin: create the account in Authentication, then set
///     `role: "admin"` on its `users/{uid}` document.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    // Hot restart on Android can find the native default app already set up.
    if (e.code != 'duplicate-app') rethrow;
  }
  runApp(const ColomboPalApp());
}
