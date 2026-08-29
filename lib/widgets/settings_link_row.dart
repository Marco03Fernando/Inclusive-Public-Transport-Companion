import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SettingsLinkRow extends StatelessWidget {
  const SettingsLinkRow({super.key, required this.label, required this.onTap, this.trailingText});

  final String label;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.text)),
            if (trailingText != null)
              Text(trailingText!, style: TextStyle(fontSize: 13, color: palette.muted))
            else
              Icon(Icons.chevron_right, color: palette.muted),
          ],
        ),
      ),
    );
  }
}
