import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// Presentation-only building blocks for the passenger Home screen. Taps and
/// data stay in `home_screen.dart`.

/// Full-width primary action (Plan Journey): icon, text and a chevron.
class HomeFeatureCard extends StatelessWidget {
  const HomeFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;

  /// Optional artwork shown instead of the icon badge.
  final String? imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(20);
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
                child: Row(
                  children: [
                    if (imageAsset != null)
                      ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            imageAsset!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      _IconBadge(icon: icon, color: palette.accent, size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: palette.accent),
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

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      ),
    );
  }
}

/// Wide banner with the Colombo waterfront artwork on the right.
class HomeExploreBanner extends StatelessWidget {
  const HomeExploreBanner({
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
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: palette.accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: palette.isHighContrast
              ? BorderSide(color: palette.cardBorder, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        // Zoomed slightly to crop the soft border baked
                        // into the artwork.
                        child: Transform.scale(
                          scale: 1.25,
                          child: Image.asset(
                            'assets/artwork/route_map_pin.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 88),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 112, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: palette.text,
                        ),
                      ),
                    ],
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
