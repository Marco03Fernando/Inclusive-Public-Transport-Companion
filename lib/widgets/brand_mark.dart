import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// The ColomboPal symbol (bus + Lotus Tower) on a white disc. The artwork
/// has an opaque white canvas, so it always sits on white — in dark mode
/// too — and the disc gets a soft shadow / outline to lift it off the page.
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, this.size = 44});

  static const asset = AssetImage('assets/branding/app/colombopal_icon.png');

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: palette.isHighContrast
              ? Border.all(color: palette.cardBorder, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: size / 4,
              offset: Offset(0, size / 14),
            ),
          ],
        ),
        child: ClipOval(
          child: Image(image: asset, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      ),
    );
  }
}

/// [BrandBadge] + "Colombo Pal" wordmark, read as one "Colombo Pal" label.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.badgeSize = 44, this.fontSize = 20});

  final double badgeSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'Colombo Pal',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandBadge(size: badgeSize),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Colombo ',
                      style: TextStyle(color: palette.text),
                    ),
                    TextSpan(
                      text: 'Pal',
                      style: TextStyle(color: palette.accent),
                    ),
                  ],
                ),
                maxLines: 1,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
