import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Decorative Colombo waterfront: sun, clouds, a soft skyline with the
/// Lotus Tower, and the Beira Lake water line. Drawn from the palette (no
/// image assets), so it follows light / dark / high-contrast themes and
/// scales to any size. Purely decorative — hidden from screen readers.
class ColomboSkyline extends StatelessWidget {
  const ColomboSkyline({super.key, this.showSun = true, this.towerAt = 0.44});

  final bool showSun;

  /// Horizontal position of the Lotus Tower, as a fraction of the width.
  final double towerAt;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SkylinePainter(
            context.palette,
            showSun: showSun,
            towerAt: towerAt,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  _SkylinePainter(this.palette, {required this.showSun, required this.towerAt});

  final AppPalette palette;
  final bool showSun;
  final double towerAt;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ground = h * 0.80;

    if (showSun) {
      canvas.drawCircle(
        Offset(w * 0.84, h * 0.20),
        h * 0.075,
        Paint()..color = palette.warn.withValues(alpha: 0.30),
      );
    }

    final cloud = Paint()..color = palette.surface.withValues(alpha: 0.75);
    void drawCloud(double cx, double cy, double s) {
      canvas
        ..drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: s * 2.4, height: s),
          cloud,
        )
        ..drawCircle(Offset(cx - s * 0.35, cy - s * 0.3), s * 0.42, cloud)
        ..drawCircle(Offset(cx + s * 0.25, cy - s * 0.38), s * 0.5, cloud);
    }

    drawCloud(w * 0.18, h * 0.22, h * 0.09);
    drawCloud(w * 0.60, h * 0.13, h * 0.07);

    // Back row of towers (lighter), then front row (stronger).
    final back = Paint()..color = palette.accent.withValues(alpha: 0.16);
    final front = Paint()..color = palette.accent.withValues(alpha: 0.28);
    const backRow = [
      (0.02, 0.10, 0.36),
      (0.13, 0.08, 0.48),
      (0.23, 0.09, 0.30),
      (0.62, 0.08, 0.44),
      (0.72, 0.10, 0.34),
      (0.86, 0.09, 0.50),
    ];
    const frontRow = [
      (0.06, 0.08, 0.24),
      (0.18, 0.07, 0.32),
      (0.29, 0.09, 0.22),
      (0.56, 0.07, 0.28),
      (0.66, 0.09, 0.20),
      (0.78, 0.08, 0.30),
      (0.90, 0.09, 0.22),
    ];
    for (final (x, bw, bh) in backRow) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(w * x, ground - h * bh, w * bw, h * bh),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        back,
      );
    }

    // Lotus Tower: slim shaft, green collar, pink bud, spire.
    final towerX = w * towerAt;
    final towerTop = ground - h * 0.66;
    final shaft = Paint()..color = palette.success.withValues(alpha: 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          towerX - w * 0.012,
          towerTop + h * 0.12,
          w * 0.024,
          ground - towerTop - h * 0.12,
        ),
        const Radius.circular(2),
      ),
      shaft,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(towerX, towerTop + h * 0.07),
        width: w * 0.07,
        height: h * 0.14,
      ),
      Paint()..color = palette.cta.withValues(alpha: 0.60),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        towerX - w * 0.004,
        towerTop - h * 0.08,
        w * 0.008,
        h * 0.09,
      ),
      Paint()..color = palette.muted.withValues(alpha: 0.55),
    );

    for (final (x, bw, bh) in frontRow) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(w * x, ground - h * bh, w * bw, h * bh),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        front,
      );
    }

    // Water with two soft ripple lines.
    canvas.drawRect(
      Rect.fromLTWH(0, ground, w, h - ground),
      Paint()..color = palette.accent.withValues(alpha: 0.14),
    );
    final ripple = Paint()
      ..color = palette.surface.withValues(alpha: 0.7)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final (y, x0, x1) in [
      (0.87, 0.10, 0.34),
      (0.87, 0.58, 0.80),
      (0.94, 0.30, 0.52),
    ]) {
      canvas.drawLine(Offset(w * x0, h * y), Offset(w * x1, h * y), ripple);
    }
  }

  @override
  bool shouldRepaint(_SkylinePainter old) =>
      old.palette != palette ||
      old.showSun != showSun ||
      old.towerAt != towerAt;
}
