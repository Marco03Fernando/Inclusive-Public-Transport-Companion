import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/condition_tile.dart';

/// "My Reports": the signed-in user's submitted condition reports and their
/// review status, loaded from Firestore via [ReportsProvider] →
/// `ConditionReportService` → `FirebaseConditionReportRepository`.
class ReportMineScreen extends StatelessWidget {
  const ReportMineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final role = context.watch<AppState>().role;
    final provider = context.watch<ReportsProvider>();
    final reports = provider.reports;

    final Widget content;
    if (provider.isLoading && reports.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (provider.error != null && reports.isEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(provider.error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: palette.danger)),
          const SizedBox(height: 14),
          SecondaryButton(label: context.t('tryAgain'), onPressed: provider.loadReports),
        ],
      );
    } else if (reports.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: palette.muted),
            const SizedBox(height: 12),
            Text(
              context.t('noReportsYet'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.text),
            ),
            const SizedBox(height: 4),
            Text(
              context.t('noReportsNote'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final report in reports) ...[
            ConditionTile.fromReport(report),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Text(
            context.t('reportsReviewNote'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
        ],
      );
    }

    return AppScaffold(
      routeName: Routes.reportMine,
      title: context.t('myReportsTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.homeFor(role)),
      scrollableBody: false,
      body: RefreshIndicator(
        onRefresh: provider.loadReports,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [content],
        ),
      ),
    );
  }
}
