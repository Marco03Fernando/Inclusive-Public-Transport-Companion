import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';
import '../models/condition_report.dart';

/// Review-status pill for condition reports — used on "My Reports", the
/// route-conditions / community lists, and the admin module.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.label});

  final ReportStatus status;

  /// Overrides the default localized status label.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (color, bg) = switch (status) {
      ReportStatus.verified || ReportStatus.accepted => (palette.success, palette.successSoft),
      ReportStatus.rejected => (palette.danger, palette.dangerSoft),
      ReportStatus.underReview => (palette.warn, palette.warnSoft),
    };
    final text = label ?? context.t(status.labelKey);
    return Semantics(
      label: 'Status $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}

/// The "High"/"Medium" access-score pill on route option cards.
class AccessScoreBadge extends StatelessWidget {
  const AccessScoreBadge({super.key, required this.label, required this.high});

  final String label;
  final bool high;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = high ? palette.accent : palette.muted;
    final bg = high ? palette.accentSoft : palette.surface2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
