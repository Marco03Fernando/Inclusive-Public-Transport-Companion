import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// Tappable action card used for Home's Plan/Share actions (half-width)
/// and the wide report / community-reports actions.
///
/// With an [icon] it renders the dashboard style: tinted icon tile,
/// title + description, and a trailing chevron showing it navigates. It is
/// announced as one button ("Report a Condition, Help keep transport info
/// accurate") with the icon and chevron left out as decoration. The card
/// grows vertically with large text — no fixed heights.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(18);

    final text = Column(
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
        Text(
          description,
          style: TextStyle(fontSize: 12.5, color: palette.muted, height: 1.35),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: palette.isHighContrast
                ? BorderSide(color: palette.cardBorder, width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: icon == null
                    ? SizedBox(width: double.infinity, child: text)
                    : Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.accentSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, size: 22, color: palette.accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: text),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: palette.muted,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
