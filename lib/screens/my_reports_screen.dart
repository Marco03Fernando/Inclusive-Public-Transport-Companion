import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reports_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';
import 'report_condition_step1_screen.dart';

/// Screen 3: "My Reports (Status)"
///
/// Shows the signed-in user's submitted reports (loaded from Firestore
/// via `ReportsProvider` → `ConditionReportService` →
/// `FirebaseConditionReportRepository`) with their review status, plus
/// an SOS button. Matches wireframe "12 My Reports (Status)".
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  void _onSosPressed(BuildContext context) {
    // NOTE: no backend / emergency-call integration wired up yet.
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text('SOS'),
        content: const Text(
          'Emergency assistance is not connected yet in this preview.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final reports = reportsProvider.reports;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Reports'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Semantics(
              button: true,
              label: 'SOS emergency button',
              child: InkWell(
                onTap: () => _onSosPressed(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.black, width: 2),
                    ),
                  ),
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: reportsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reports.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: reports.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            if (index == reports.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                child: Text(
                                  'Reports are checked by an admin\nbefore being marked Verified.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              );
                            }
                            return ReportCard(report: reports[index]);
                          },
                        ),
            ),
            const _BottomNavBar(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ReportConditionStep1Screen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('REPORT'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.assignment_outlined, size: 40, color: AppColors.grey300),
            SizedBox(height: AppSpacing.md),
            Text(
              'No reports yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Reports you submit will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple bottom navigation bar (Home / Reports / Profile) as shown in
/// the wireframe. Only "Reports" is wired to represent the active tab;
/// the others are placeholders for future screens.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.grey300, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavLabel(text: 'Home', active: false),
          _NavLabel(text: 'Reports', active: true),
          _NavLabel(text: 'Profile', active: false),
        ],
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  final String text;
  final bool active;

  const _NavLabel({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
        color: active ? AppColors.black : AppColors.grey600,
      ),
    );
  }
}
