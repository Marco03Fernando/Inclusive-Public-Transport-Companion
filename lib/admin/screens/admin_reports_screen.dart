import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../models/report_filter.dart';
import '../providers/admin_reports_provider.dart';
import '../widgets/admin_message_state.dart';
import '../widgets/admin_report_card.dart';
import '../widgets/status_filter_bar.dart';
import 'admin_report_details_screen.dart';

/// Report management: every report in `condition_reports`, filterable by
/// status. Updates live — a report reviewed on another device moves
/// between tabs by itself.
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminReportsProvider>();
    final reports = provider.reports;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xs),
            StatusFilterBar(
              selected: provider.filter,
              stats: provider.stats,
              onChanged: provider.setFilter,
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading && provider.allReports.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && provider.allReports.isEmpty) {
                    return AdminMessageState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load reports',
                      message: provider.error!,
                      actionLabel: 'TRY AGAIN',
                      onAction: provider.retry,
                    );
                  }

                  if (reports.isEmpty) {
                    return AdminMessageState(
                      icon: Icons.assignment_outlined,
                      title: 'Nothing here',
                      message: provider.filter.emptyMessage,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return AdminReportCard(
                        report: report,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminReportDetailsScreen(initialReport: report),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
