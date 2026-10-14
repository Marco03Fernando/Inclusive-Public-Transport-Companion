import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Checkbox-style row for accessibility needs — shared by the sign-up
/// accessibility step and the profile accessibility-preferences screen.
class AccessNeedTile extends StatelessWidget {
  const AccessNeedTile({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: checked ? palette.ctaSoft : palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: checked ? palette.cta : palette.border, width: 1.5),
          boxShadow: checked ? [BoxShadow(color: palette.cta.withValues(alpha: 0.16), blurRadius: 10, offset: const Offset(0, 3))] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? palette.cta : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: checked ? palette.cta : palette.border, width: 1.5),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, color: palette.text)),
            ),
          ],
        ),
      ),
    );
  }
}
