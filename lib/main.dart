import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/reports_provider.dart';
import 'repositories/local_condition_report_repository.dart';
import 'screens/my_reports_screen.dart';
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
/// through `ConditionReportService`, which currently talks to
/// `LocalConditionReportRepository` (on-device storage, no backend).
///
/// To connect a real backend later, change ONLY the line below:
///   repository: RemoteConditionReportRepository(baseUrl: 'https://your-api.example.com'),
/// Nothing in `screens/`, `widgets/`, or `providers/` needs to change.
void main() {
  runApp(const ColomboPalApp());
}

class ColomboPalApp extends StatelessWidget {
  const ColomboPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ConditionReportService>(
          create: (_) => ConditionReportService(
            repository: LocalConditionReportRepository(),
          ),
        ),
        ChangeNotifierProvider<ReportsProvider>(
          create: (context) => ReportsProvider(
            service: context.read<ConditionReportService>(),
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
            data: mq.copyWith(textScaler: clampedScale),
            child: child!,
          );
        },
        home: const MyReportsScreen(),
      ),
    );
  }
}
