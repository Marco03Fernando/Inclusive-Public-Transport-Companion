import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/route_option.dart';

/// A numbered step with a vertical dashed connector, used on the route
/// detail screen's step-by-step list.
class RouteStepItem extends StatelessWidget {
  const RouteStepItem({super.key, required this.step, required this.isLast});

  final RouteStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                child: Text(
                  '${step.n}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: palette.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: palette.text)),
                  const SizedBox(height: 2),
                  Text(step.detail, style: TextStyle(fontSize: 12, color: palette.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
