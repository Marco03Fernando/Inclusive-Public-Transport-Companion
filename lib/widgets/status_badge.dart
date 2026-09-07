import 'package:flutter/material.dart';

import '../models/condition_report.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final style = _getStyle(status.label);

    return Semantics(
      label: 'Status ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: style.textColor,
            width: 1,
          ),
        ),
        child: Text(
          status.label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: style.textColor,
          ),
        ),
      ),
    );
  }

  _BadgeStyle _getStyle(String label) {
    final value = label.toLowerCase();

    if (value.contains('approved') ||
        value.contains('verified') ||
        value.contains('completed')) {
      return const _BadgeStyle(
        backgroundColor: Color(0xFFDCFCE7),
        textColor: Color(0xFF166534),
      );
    }

    if (value.contains('rejected') ||
        value.contains('declined')) {
      return const _BadgeStyle(
        backgroundColor: Color(0xFFFEE2E2),
        textColor: Color(0xFFB91C1C),
      );
    }

    if (value.contains('pending') ||
        value.contains('review')) {
      return const _BadgeStyle(
        backgroundColor: Color(0xFFFEF3C7),
        textColor: Color(0xFF92400E),
      );
    }

    return const _BadgeStyle(
      backgroundColor: AppColors.grey200,
      textColor: AppColors.grey700,
    );
  }
}

class _BadgeStyle {
  final Color backgroundColor;
  final Color textColor;

  const _BadgeStyle({
    required this.backgroundColor,
    required this.textColor,
  });
}