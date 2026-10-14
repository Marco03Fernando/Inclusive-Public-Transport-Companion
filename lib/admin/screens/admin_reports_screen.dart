import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/screen_header.dart';
import '../models/report_filter.dart';
import '../providers/admin_reports_provider.dart';
import '../widgets/admin_message_state.dart';
import '../widgets/admin_report_card.dart';
import '../widgets/status_filter_bar.dart';
import 'admin_report_details_screen.dart';

/// Report management: every report in `condition_reports`, filterable by
/// status. Updates live — a report reviewed on another device moves
/// between filters by itself.
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminReportsProvider>();
    final reports = provider.reports;

    final Widget body;
    if (provider.isLoading && provider.allReports.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && provider.allReports.isEmpty) {
      body = AdminMessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load reports',
        message: provider.error!,
        actionLabel: 'Try again',
        onAction: provider.retry,
      );
    } else if (reports.isEmpty) {
      body = AdminMessageState(
        icon: Icons.assignment_outlined,
        title: 'Nothing here',
        message: provider.filter.emptyMessage,
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final report = reports[index];
          return AdminReportCard(
            report: report,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminReportDetailsScreen(initialReport: report),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: const ScreenHeader(title: 'Reports'),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: StatusFilterBar(
                selected: provider.filter,
                stats: provider.stats,
                onChanged: provider.setFilter,
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
