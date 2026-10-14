import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A single toggle chip (route filters, report target/type pickers, the
/// volunteer feed's All/Buses/Stations filter).
///
/// Announced as a button with its selected state; at least 48dp tall; a
/// check mark shows selection without relying on colour alone.
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? palette.ctaSoft : palette.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? palette.cta : palette.border,
              width: selected || palette.isHighContrast ? 2 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.cta.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: palette.text),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? palette.text : palette.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
