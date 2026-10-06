import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/section_label.dart';
import '../models/report_filter.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_reports_provider.dart';
import '../widgets/admin_message_state.dart';
import '../widgets/admin_stat_card.dart';
import 'admin_reports_screen.dart';

/// Admin home: live counts of total / pending / accepted / rejected
/// reports. Tapping a card opens the report list on that status.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _openReports(BuildContext context, ReportFilter filter) {
    context.read<AdminReportsProvider>().setFilter(filter);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<AdminReportsProvider>();
    final email = context.select<AdminAuthProvider, String?>(
      (auth) => auth.profile?.email,
    );
    final stats = reports.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AdminAuthProvider>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (reports.isLoading && reports.allReports.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (reports.error != null && reports.allReports.isEmpty) {
              return AdminMessageState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load reports',
                message: reports.error!,
                actionLabel: 'TRY AGAIN',
                onAction: reports.retry,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  email == null ? 'Signed in as admin' : 'Signed in as $email',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionLabel('Report overview'),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: AdminStatCard(
                          label: 'Total reports',
                          count: stats.total,
                          icon: Icons.assignment_outlined,
                          color: AppColors.accentDark,
                          onTap: () => _openReports(context, ReportFilter.all),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AdminStatCard(
                          label: 'Pending',
                          count: stats.pending,
                          icon: Icons.hourglass_top_outlined,
                          color: AppColors.warning,
                          onTap: () =>
                              _openReports(context, ReportFilter.underReview),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: AdminStatCard(
                          label: 'Accepted',
                          count: stats.accepted,
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                          onTap: () =>
                              _openReports(context, ReportFilter.accepted),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AdminStatCard(
                          label: 'Rejected',
                          count: stats.rejected,
                          icon: Icons.cancel_outlined,
                          color: AppColors.danger,
                          onTap: () =>
                              _openReports(context, ReportFilter.rejected),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => _openReports(
                    context,
                    stats.pending > 0
                        ? ReportFilter.underReview
                        : ReportFilter.all,
                  ),
                  child: Text(
                    stats.pending > 0
                        ? 'REVIEW PENDING REPORTS (${stats.pending})'
                        : 'VIEW ALL REPORTS',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
