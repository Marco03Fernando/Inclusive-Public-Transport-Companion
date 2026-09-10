import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/reports_provider.dart';
import 'repositories/firebase_condition_report_repository.dart';
import 'screens/my_reports_screen.dart';
import 'services/auth_service.dart';
import 'services/condition_report_service.dart';
import 'theme/app_theme.dart';

/// ColomboPal — Condition Reporting feature.
///
/// This entry point wires up the "Condition Reporting" flow:
///   1. My Reports (start screen for this preview)
///   2. Report Condition — Step 1/2
///   3. Report Condition — Step 2/2
///
/// Reports are validated, built into a `ConditionReport`, and saved
/// through `ConditionReportService`, which talks to
/// `FirebaseConditionReportRepository` (Firestore + Firebase Storage).
///
/// To point at a different backend later, change ONLY the `repository:`
/// line below — e.g. back to `LocalConditionReportRepository()` for
/// offline dev, or `RemoteConditionReportRepository(baseUrl: ...)` for a
/// custom REST API. Nothing in `screens/`, `widgets/`, or `providers/`
/// needs to change either way.
///
/// IMPORTANT — before this runs you need to:
///  1. Add `google-services.json` (Android) and `GoogleService-Info.plist`
///     (iOS) from your Firebase project, or run `flutterfire configure`
///     to generate `lib/firebase_options.dart` and pass
///     `options: DefaultFirebaseOptions.currentPlatform` to
///     `Firebase.initializeApp()` below instead.
///  2. Enable Anonymous auth in Firebase Console → Authentication →
///     Sign-in method (this app signs devices in anonymously — see
///     `services/auth_service.dart`).
///  3. Create the `condition_reports` Firestore collection (it's created
///     automatically on first write) and set security rules — see the
///     notes in `firebase_condition_report_repository.dart`.
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

        Provider<ConditionReportService>(
          create: (_) => ConditionReportService(
            repository: FirebaseConditionReportRepository(),
          ),
        ),

        ChangeNotifierProvider<ReportsProvider>(
          create: (context) => ReportsProvider(
            service: context.read<ConditionReportService>(),
            authService: context.read<AuthService>(),
          )..loadReports(),
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

        home: const MyReportsScreen(),
      ),
    );
  }
}