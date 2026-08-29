import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';
import '../models/condition_report.dart';
import 'status_badge.dart';

/// Shared row for reported conditions, "My Reports", and the volunteer
/// community feed — same shape in the design, different data sources.
class ConditionTile extends StatelessWidget {
  const ConditionTile({super.key, required this.report});

  final ConditionReport report;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final statusLabel = report.status == ReportStatus.verified
        ? context.t('verified')
        : context.t('underReview');
    final subtitle = report.date == null ? report.location : '${report.location} · ${report.date}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: palette.text)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: palette.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: report.status, label: statusLabel),
        ],
      ),
    );
  }
}
