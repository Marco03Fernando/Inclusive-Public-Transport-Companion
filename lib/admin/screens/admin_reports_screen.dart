import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/screen_header.dart';
import '../../models/report_filters.dart';
import '../models/report_filter.dart';
import '../providers/admin_reports_provider.dart';
import '../widgets/admin_message_state.dart';
import '../widgets/admin_report_card.dart';
import '../widgets/report_filter_panel.dart';
import '../widgets/status_filter_bar.dart';
import 'admin_report_details_screen.dart';

/// Report management: every report in `condition_reports`, filterable by
/// status, subject and report type, and sortable. Filters combine (e.g.
/// Buses + Accessibility Issue + Under review) and run on the admin's live
/// list in memory — no extra Firestore reads. Updates live: a report
/// reviewed on another device moves between filters by itself.
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
        icon: Icons.filter_alt_off_outlined,
        title: 'Nothing here',
        message: provider.hasExtraFilters
            ? 'No reports match this combination of filters.'
            : provider.filter.emptyMessage,
        actionLabel: provider.hasExtraFilters ? 'Clear filters' : null,
        onAction: provider.hasExtraFilters ? provider.clearFilters : null,
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
            // Filters stay pinned above the results; on small screens or
            // with very large text they get at most ~45% of the height and
            // scroll on their own, so results are always visible.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Counts are within the chosen subject + type.
                    StatusFilterBar(
                      selected: provider.filter,
                      stats: provider.scopedStats,
                      onChanged: provider.setFilter,
                    ),
                    const SizedBox(height: 12),
                    ReportFilterPanel(
                      subject: provider.subjectFilter,
                      type: provider.typeFilter,
                      sort: provider.sort,
                      shown: reports.length,
                      total: provider.allReports.length,
                      onSubjectChanged: provider.setSubjectFilter,
                      onTypeChanged: provider.setTypeFilter,
                      onSortChanged: provider.setSort,
                      onClear:
                          provider.query.isFiltered ||
                              provider.sort != ReportSort.newestFirst
                          ? provider.clearFilters
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
