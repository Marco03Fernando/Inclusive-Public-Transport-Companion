import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/condition_report.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.label});

  final ReportStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final verified = status == ReportStatus.verified;
    final color = verified ? palette.success : palette.warn;
    final bg = verified ? palette.successSoft : palette.warnSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
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
