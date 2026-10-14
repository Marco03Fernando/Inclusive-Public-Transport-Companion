import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/greeting_header.dart';
import '../models/report_filter.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_reports_provider.dart';
import '../widgets/admin_message_state.dart';
import '../widgets/admin_report_card.dart';
import '../widgets/admin_stat_card.dart';
import 'admin_report_details_screen.dart';
import 'admin_reports_screen.dart';

/// Admin home (route `/admin`, behind `AdminGate`): live counts of total /
/// under review / accepted / rejected reports from `condition_reports`,
/// plus the latest submissions. Tapping a count opens the report list on
/// that status.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const _latestCount = 3;

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthState>().signOut();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.roleSelect, (route) => false);
  }

  void _openReports(BuildContext context, ReportFilter filter) {
    context.read<AdminReportsProvider>().setFilter(filter);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AdminReportsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reports = context.watch<AdminReportsProvider>();
    final email = context.select<AdminAuthProvider, String?>(
      (auth) => auth.profile?.email,
    );
    final stats = reports.stats;

    final Widget content;
    if (reports.isLoading && reports.allReports.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (reports.error != null && reports.allReports.isEmpty) {
      content = AdminMessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load reports',
        message: reports.error!,
        actionLabel: 'Try again',
        onAction: reports.retry,
      );
    } else {
      final latest = reports.allReports.take(_latestCount).toList();
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  label: 'Total reports',
                  count: stats.total,
                  onTap: () => _openReports(context, ReportFilter.all),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Under review',
                  count: stats.pending,
                  color: palette.warn,
                  onTap: () => _openReports(context, ReportFilter.underReview),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  label: 'Accepted',
                  count: stats.accepted,
                  color: palette.success,
                  onTap: () => _openReports(context, ReportFilter.accepted),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Rejected',
                  count: stats.rejected,
                  color: palette.danger,
                  onTap: () => _openReports(context, ReportFilter.rejected),
                ),
              ),
            ],
          ),
          if (reports.skippedCount > 0) ...[
            const SizedBox(height: 12),
            _SkippedNotice(count: reports.skippedCount),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: stats.pending > 0
                ? 'Review pending reports (${stats.pending})'
                : 'View all reports',
            onPressed: () => _openReports(
              context,
              stats.pending > 0 ? ReportFilter.underReview : ReportFilter.all,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Latest reports',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 10),
          if (latest.isEmpty)
            Text(
              'No reports have been submitted yet.',
              style: TextStyle(fontSize: 13, color: palette.muted),
            )
          else
            for (final report in latest) ...[
              AdminReportCard(
                report: report,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminReportDetailsScreen(initialReport: report),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          // The list is live already; pull-to-refresh only re-subscribes
          // after an error (e.g. connection restored).
          onRefresh: () async => reports.retry(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              GreetingHeader(
                greeting: email ?? 'Signed in as admin',
                name: 'Admin dashboard',
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    const SizedBox(height: 20),
                    TextDangerButton(
                      label: 'Log out',
                      onPressed: () => _signOut(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tells the admin that some `condition_reports` documents couldn't be
/// read (missing/invalid fields) and are therefore not in the counts.
class _SkippedNotice extends StatelessWidget {
  final int count;

  const _SkippedNotice({required this.count});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.warnSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: palette.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count == 1
                  ? '1 report could not be read (malformed data) and is not shown.'
                  : '$count reports could not be read (malformed data) and are not shown.',
              style: TextStyle(fontSize: 12, color: palette.text),
            ),
          ),
        ],
      ),
    );
  }
}
