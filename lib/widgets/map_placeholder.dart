import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Diagonal-hatch placeholder standing in for a real map, with an optional
/// dashed route line — matches the design's "MAP · ..." reference tiles.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key, required this.label, this.height = 150, this.showRoute = false});

  final String label;
  final double height;
  final bool showRoute;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: palette.border))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _HatchPainter(base: palette.surface, stripe: palette.surface2),
          ),
          if (showRoute)
            CustomPaint(
              size: Size.infinite,
              painter: _RoutePainter(accent: palette.cta, danger: palette.danger),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: palette.muted, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.base, required this.stripe});

  final Color base;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    const gap = 20.0;
    final diag = size.width + size.height;
    for (double x = -size.height; x < diag; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) =>
      oldDelegate.base != base || oldDelegate.stripe != stripe;
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.accent, required this.danger});

  final Color accent;
  final Color danger;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 320;
    final h = size.height / 120;
    Offset p(double x, double y) => Offset(x * w, y * h);

    final path = Path()
      ..moveTo(p(20, 90).dx, p(20, 90).dy)
      ..cubicTo(p(90, 90).dx, p(90, 90).dy, p(100, 30).dx, p(100, 30).dy, p(170, 30).dx, p(170, 30).dy)
      ..cubicTo(p(210, 30).dx, p(210, 30).dy, p(250, 70).dx, p(250, 70).dy, p(300, 20).dx, p(300, 20).dy);

    final dashPaint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_dashPath(path, 2 * w, 7 * w), dashPaint);

    canvas.drawCircle(p(20, 90), 6 * w, Paint()..color = accent);
    canvas.drawCircle(p(300, 20), 6 * w, Paint()..color = danger);
  }

  Path _dashPath(Path source, double dashLength, double gapLength) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        final next = (distance + len).clamp(0, metric.length);
        if (draw) dashed.addPath(metric.extractPath(distance, next.toDouble()), Offset.zero);
        distance = next.toDouble();
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => false;
}
