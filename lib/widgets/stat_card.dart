import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// Statistic tile on Volunteer Home ("14 / Reports submitted").
///
/// Announced as a single phrase — [semanticsLabel] if given (e.g.
/// "Reports submitted: 14"), otherwise "label: value" — so screen readers
/// never read the number and label out of order. The value scales with
/// text size but never clips; the card grows instead.
///
/// With [onTap] the whole card is one button (ripple feedback, an arrow
/// affordance, and [semanticsHint] such as "Opens My Reports").
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
    this.icon,
    this.semanticsLabel,
    this.semanticsHint,
    this.onTap,
  });

  final String value;
  final String label;
  final Color? valueColor;
  final IconData? icon;
  final String? semanticsLabel;
  final String? semanticsHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = valueColor ?? palette.accent;

    final radius = BorderRadius.circular(18);
    final interactive = onTap != null;

    return Semantics(
      label: semanticsLabel ?? '$label: $value',
      hint: semanticsHint,
      button: interactive,
      onTap: onTap,
      excludeSemantics: true,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null || interactive) ...[
                    Row(
                      children: [
                        if (icon != null)
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tint.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, size: 20, color: tint),
                          ),
                        const Spacer(),
                        if (interactive)
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: palette.muted,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1.1,
                      color: valueColor ?? palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
