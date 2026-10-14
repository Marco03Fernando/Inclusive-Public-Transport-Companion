import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';
import '../models/public_condition_report.dart';
import 'condition_tile.dart';
import 'status_badge.dart';

/// One published report in Community Reports. The whole card is a single
/// button that opens Report Details; screen readers hear one summary
/// ("Bus NB-1234 · Broken ramp, Accessibility Issue · Bus route 138, …,
/// Verified, button, Opens report details").
class CommunityReportCard extends StatelessWidget {
  const CommunityReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  final PublicConditionReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final contributor =
        report.contributorName ?? context.t('anonymousContributor');
    final metaStyle = TextStyle(fontSize: 12.5, color: palette.muted);

    return Semantics(
      button: true,
      hint: context.t('opensReportDetails'),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
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
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                report.headline,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: palette.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              status: report.status,
                              label: context.t('communityVerified'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ReportTypeLine(
                          reportType: report.reportType,
                          routeLabel: report.routeLabel,
                        ),
                        const SizedBox(height: 6),
                        _MetaLine(
                          icon: Icons.place_outlined,
                          text:
                              '${context.t(report.subject.labelKey)} · '
                              '${report.locationLabel}',
                          style: metaStyle,
                        ),
                        const SizedBox(height: 2),
                        _MetaLine(
                          icon: Icons.person_outline,
                          text:
                              '${context.tf('reportedByName', {'name': contributor})}'
                              ' · ${report.submittedLabel}',
                          style: metaStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.chevron_right,
                        color: palette.muted,
                        size: 22,
                      ),
                    ),
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    required this.style,
  });

  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: style.color),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
