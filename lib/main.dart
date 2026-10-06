import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin/providers/admin_auth_provider.dart';
import 'admin/providers/admin_reports_provider.dart';
import 'admin/repositories/firebase_admin_report_repository.dart';
import 'admin/services/admin_auth_service.dart';
import 'admin/services/admin_report_service.dart';
import 'providers/auth_provider.dart';
import 'providers/reports_provider.dart';
import 'repositories/firebase_condition_report_repository.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/condition_report_service.dart';
import 'theme/app_theme.dart';

/// ColomboPal — single entry point for users AND admins.
///
/// Flow:
///   App → Login / Register (Firebase Auth, email + password)
///       → read `users/{uid}.role` from Firestore
///       → role "user"  → My Reports (report conditions)
///       → role "admin" → Admin Dashboard (review / delete reports)
///
/// Routing lives in `screens/auth_gate.dart`. Registration always creates
/// `users/{uid}` with `role: "user"`; admin accounts are set up by hand in
/// the Firebase console (see `services/auth_service.dart`).
///
/// Wiring (both sides): Screen → Provider → Service → Repository → Firebase.
/// Reports live in the `condition_reports` collection, photos in Firebase
/// Storage at `condition_reports/{userId}/{reportId}.jpg`.
///
/// IMPORTANT — Firebase console setup:
///  1. Authentication → Sign-in method → enable Email/Password.
///  2. Deploy `firestore.rules` and `storage.rules` from the project root
///     (`firebase deploy --only firestore:rules,storage`) — they are what
///     actually stop normal users from reading or changing admin data.
///  3. For each admin: create the account in Authentication, then a
///     Firestore document `users/{uid}` with
///     `{ name: "Admin", email: "...", role: "admin" }`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  runApp(const ColomboPalApp());
}

class ColomboPalApp extends StatelessWidget {
  const ColomboPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),

        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            service: context.read<AuthService>(),
          ),
        ),

        // ---- User side ----

        Provider<ConditionReportService>(
          create: (_) => ConditionReportService(
            repository: FirebaseConditionReportRepository(),
          ),
        ),

        // Loads the signed-in USER's reports on login and clears them on
        // sign-out, so one account never sees another account's list.
        ChangeNotifierProxyProvider<AuthProvider, ReportsProvider>(
          create: (context) => ReportsProvider(
            service: context.read<ConditionReportService>(),
            authService: context.read<AuthService>(),
          ),
          update: (context, auth, reports) {
            final isUser =
                auth.status == AuthStatus.authenticated && !auth.isAdmin;
            reports!.syncSession(userId: isUser ? auth.profile!.uid : null);
            return reports;
          },
        ),

        // ---- Admin side ----

        Provider<AdminAuthService>(
          create: (_) => AdminAuthService(),
        ),

        Provider<AdminReportService>(
          create: (_) => AdminReportService(
            repository: FirebaseAdminReportRepository(),
          ),
        ),

        // Independently verifies users/{uid}.role == "admin".
        ChangeNotifierProvider<AdminAuthProvider>(
          create: (context) => AdminAuthProvider(
            service: context.read<AdminAuthService>(),
          ),
          lazy: false,
        ),

        // Live subscription to ALL reports that only runs while a VERIFIED
        // admin is signed in: it starts on sign-in and is cancelled +
        // cleared on sign-out, so normal users never open it.
        ChangeNotifierProxyProvider<AdminAuthProvider, AdminReportsProvider>(
          create: (context) => AdminReportsProvider(
            service: context.read<AdminReportService>(),
          ),
          update: (context, adminAuth, reports) {
            reports!.syncSession(isAdmin: adminAuth.isAdmin);
            return reports;
          },
        ),
      ],
      child: MaterialApp(
        title: 'ColomboPal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),

        // Large system text scale support for elderly users:
        // respects the device accessibility text-size setting up to a cap
        // so layouts don't break.
        builder: (context, child) {
          final mq = MediaQuery.of(context);

          final clampedScale = mq.textScaler.clamp(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.3,
          );

          return MediaQuery(
            data: mq.copyWith(
              textScaler: clampedScale,
            ),
            child: child!,
          );
        },

        home: const AuthGate(),
      ),
    );
  }
}