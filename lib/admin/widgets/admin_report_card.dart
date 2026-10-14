import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/condition_report.dart';
import '../../utils/admin_formatters.dart';
import '../../widgets/condition_tile.dart';
import '../../widgets/status_badge.dart';

/// One report in the admin list: subject + vehicle/station number, report
/// type, bus route, condition type, location, submitted date, and current
/// status.
///
/// Same surface/shadow style as the app's `ConditionTile`, and reuses the
/// shared `StatusBadge`.
class AdminReportCard extends StatelessWidget {
  final ConditionReport report;
  final VoidCallback onTap;

  const AdminReportCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final submitted = AdminFormat.dateTime(report.createdAt);
    final location = AdminFormat.locationName(report);
    final hasPhoto = (report.photoUrl ?? '').isNotEmpty;

    return Semantics(
      button: true,
      label:
          '${report.title}, ${report.reportType.label}, '
          'bus route ${report.routeLabel}, '
          '${report.conditionType.sentenceCase}, '
          'location $location, submitted $submitted, '
          'status ${report.status.label}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ReportTypeLine(
                    reportType: report.reportType,
                    routeLabel: report.routeLabel,
                  ),
                  const SizedBox(height: 4),
                  _MetaRow(
                    icon: Icons.category_outlined,
                    text: report.conditionType.sentenceCase,
                  ),
                  const SizedBox(height: 4),
                  _MetaRow(icon: Icons.place_outlined, text: location),
                  const SizedBox(height: 4),
                  _MetaRow(
                    icon: hasPhoto ? Icons.photo_outlined : Icons.schedule,
                    text: hasPhoto ? '$submitted · photo attached' : submitted,
                  ),
                ],
              ),
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
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: palette.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
        ),
      ],
    );
  }
}
