import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The welcome screen's animated mark: a location pin that idles with a
/// gentle breathe + glow, and plays a confident one-shot "confirm" hop —
/// triggered via [LivingPinLogoState.playConfirm] — when the user actually
/// picks a role. Built natively (AnimationController + CustomPainter) as a
/// stand-in for a future Rive state machine: the same idle/confirm shape,
/// swappable for a real `.riv` asset later without touching call sites.
class LivingPinLogo extends StatefulWidget {
  const LivingPinLogo({super.key, this.size = 72});

  final double size;

  @override
  State<LivingPinLogo> createState() => LivingPinLogoState();
}

class LivingPinLogoState extends State<LivingPinLogo> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat(reverse: true);
  late final AnimationController _confirm = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  /// Plays the one-shot "confirm" hop. Call this right before navigating
  /// away so the user sees the mark react to their tap.
  Future<void> playConfirm() {
    return _confirm.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: widget.size * 1.6,
      height: widget.size * 1.6,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _confirm]),
        builder: (context, _) {
          final breathe = 1 + 0.06 * Curves.easeInOut.transform(_idle.value);
          final hop = sin(_confirm.value * pi);
          final scale = breathe + hop * 0.2;
          final lift = hop * (widget.size * 0.12);
          final glowOpacity = 0.18 + 0.22 * _idle.value + hop * 0.25;

          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: glowOpacity.clamp(0.0, 0.7),
                child: Container(
                  width: widget.size * 1.5,
                  height: widget.size * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [palette.heroGradientStart, palette.heroGradientStart.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -lift),
                child: Transform.scale(
                  scale: scale,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _PinPainter(start: palette.heroGradientStart, end: palette.heroGradientEnd),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.start, required this.end});

  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 56;
    canvas.save();
    canvas.scale(scale);

    final path = Path()
      ..moveTo(28, 4)
      ..cubicTo(17, 4, 9, 12.5, 9, 23)
      ..cubicTo(9, 38, 28, 52, 28, 52)
      ..cubicTo(28, 52, 47, 38, 47, 23)
      ..cubicTo(47, 12.5, 39, 4, 28, 4)
      ..close();

    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
    ).createShader(const Rect.fromLTWH(0, 0, 56, 56));

    final fillPaint = Paint()..shader = shader;
    canvas.drawShadow(path, Colors.black, 6, true);
    canvas.drawPath(path, fillPaint);
    canvas.drawCircle(const Offset(28, 23), 8, Paint()..color = Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) => oldDelegate.start != start || oldDelegate.end != end;
}
