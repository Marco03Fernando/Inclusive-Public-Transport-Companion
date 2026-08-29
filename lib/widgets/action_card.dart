import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// The bordered, left-aligned card used for Home's Plan/Share actions
/// (half-width) and the wide report/community-reports actions.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 12, color: palette.muted)),
          ],
        ),
      ),
    );
  }
}
