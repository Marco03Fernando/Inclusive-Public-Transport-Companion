import 'package:flutter/material.dart';

/// A bundled illustration in a rounded frame. Some artwork has a soft,
/// blurred border baked in; [zoom] > 1 crops it away. Decorative, so hidden
/// from screen readers.
class ArtworkImage extends StatelessWidget {
  const ArtworkImage(
    this.asset, {
    super.key,
    required this.aspectRatio,
    this.zoom = 1,
    this.radius = 28,
    this.maxWidth = 380,
  });

  final String asset;
  final double aspectRatio;
  final double zoom;
  final double radius;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Transform.scale(
              scale: zoom,
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
