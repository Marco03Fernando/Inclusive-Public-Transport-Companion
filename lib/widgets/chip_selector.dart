import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A single toggle chip (route filters, report target/type pickers, the
/// volunteer feed's All/Buses/Stations filter).
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? palette.ctaSoft : palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.cta : palette.border,
            width: 1.5,
          ),
          boxShadow: selected ? [BoxShadow(color: palette.cta.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? palette.cta : palette.muted,
          ),
        ),
      ),
    );
  }
}
