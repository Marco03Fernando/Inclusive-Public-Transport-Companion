import 'package:flutter/material.dart';

/// The Colombo Pal icon artwork (`colombopal_mark.png`) in a white circle.
/// The artwork has a white canvas, so the circle keeps it clean in dark mode.
/// Decorative — callers label the surrounding screen.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/branding/colombopal_mark.png',
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
        ),
      ),
    );
  }
}
