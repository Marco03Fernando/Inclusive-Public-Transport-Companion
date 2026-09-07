import 'package:flutter/material.dart';
import '../models/condition_report.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Rounded card showing one submitted report: title, submitted-at label,
/// and a status badge. Used in [MyReportsScreen].
class ReportCard extends StatelessWidget {
  final ConditionReport report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${report.title}, ${report.submittedLabel}, status ${report.status.label}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.black, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              report.submittedLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            StatusBadge(status: report.status),
          ],
        ),
      ),
    );
  }
}
