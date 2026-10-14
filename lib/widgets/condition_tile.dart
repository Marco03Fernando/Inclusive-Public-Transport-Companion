import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/condition_report.dart';
import 'status_badge.dart';

/// Shared row for reported conditions, "My Reports", and the volunteer
/// community feed — same shape in the design, different data sources.
class ConditionTile extends StatelessWidget {
  const ConditionTile({
    super.key,
    required this.title,
    required this.location,
    required this.status,
    this.date,
  });

  /// A real submitted report (title, location, "Submitted …" line, status).
  ConditionTile.fromReport(ConditionReport report, {super.key})
    : title = '${report.title} · ${report.conditionType.sentenceCase}',
      location = report.location.label,
      status = report.status,
      date = report.submittedLabel;

  final String title;
  final String location;
  final ReportStatus status;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subtitle = date == null
        ? location
        : location.isEmpty
        ? date!
        : '$location · $date';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: status),
        ],
      ),
    );
  }
}
