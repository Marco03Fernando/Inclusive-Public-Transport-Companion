import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A small "Label / value" pair. The value is selectable so an admin can
/// long-press to copy a user ID, report ID, or coordinates.
class AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const AdminInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}
