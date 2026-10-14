import 'package:flutter/material.dart';

import '../../widgets/stat_card.dart';

/// One dashboard counter, e.g. "12 / Under review" — the app's [StatCard]
/// made tappable (opens the report list pre-filtered to that status).
class AdminStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.count,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label: $count',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: StatCard(value: '$count', label: label, valueColor: color),
      ),
    );
  }
}
