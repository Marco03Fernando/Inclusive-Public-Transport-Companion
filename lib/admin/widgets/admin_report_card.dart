import 'package:flutter/material.dart';

import '../../models/condition_report.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../utils/admin_formatters.dart';

/// One report in the admin list: subject + vehicle/station number,
/// condition type, location, submitted date, and current status.
///
/// Same visual language as the user-side `ReportCard` (white card, black
/// 1.5px border) and reuses the existing `StatusBadge`.
class AdminReportCard extends StatelessWidget {
  final ConditionReport report;
  final VoidCallback onTap;

  const AdminReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final submitted = AdminFormat.dateTime(report.createdAt);
    final location = AdminFormat.locationName(report);

    return Semantics(
      button: true,
      label: '${report.title}, ${report.conditionType.sentenceCase}, '
          'location $location, submitted $submitted, '
          'status ${report.status.label}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.black, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // "Bus NB-1234", "Station Fort", "Rest area" ...
                      child: Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(status: report.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  icon: Icons.report_problem_outlined,
                  text: report.conditionType.sentenceCase,
                ),
                const SizedBox(height: 6),
                _MetaRow(icon: Icons.place_outlined, text: location),
                const SizedBox(height: 6),
                _MetaRow(icon: Icons.schedule, text: submitted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.grey600),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.grey700,
            ),
          ),
        ),
      ],
    );
  }
}
