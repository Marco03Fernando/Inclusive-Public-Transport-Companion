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
    this.reportType,
    this.routeLabel,
  });

  /// A real submitted report (title, report type, bus route, location,
  /// "Submitted …" line, status).
  ConditionTile.fromReport(ConditionReport report, {super.key})
    : title = '${report.title} · ${report.conditionType.sentenceCase}',
      location = report.location.label,
      status = report.status,
      date = report.submittedLabel,
      reportType = report.reportType,
      routeLabel = report.routeLabel;

  final String title;
  final String location;
  final ReportStatus status;
  final String? date;

  /// Shown (with [routeLabel]) only for real reports — null for tiles
  /// built from other data sources.
  final ReportType? reportType;
  final String? routeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subtitle = date == null
        ? location
        : location.isEmpty
        ? date!
        : '$location · $date';
    // Read as one item: title, type/route, location/date, status.
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: palette.cardOutline,
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
                  if (reportType != null) ...[
                    const SizedBox(height: 4),
                    ReportTypeLine(
                      reportType: reportType!,
                      routeLabel: routeLabel,
                    ),
                  ],
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
      ),
    );
  }
}

/// "Positive Accessibility Feedback · Bus route 138" with a matching icon:
/// green thumbs-up for positive, red warning for issues, muted for legacy
/// (unclassified) reports.
class ReportTypeLine extends StatelessWidget {
  const ReportTypeLine({super.key, required this.reportType, this.routeLabel});

  final ReportType reportType;
  final String? routeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (IconData icon, Color color) = switch (reportType) {
      ReportType.positive => (Icons.thumb_up_alt_outlined, palette.success),
      ReportType.issue => (Icons.report_problem_outlined, palette.danger),
      ReportType.unknown => (Icons.help_outline, palette.muted),
    };
    final route = routeLabel;
    final text = route == null
        ? reportType.label
        : '${reportType.label} · Bus route $route';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
