import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The 3-segment progress bar shown across the sign-up flow.
class ProgressSteps extends StatelessWidget {
  const ProgressSteps({super.key, required this.step, this.total = 3});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: List.generate(total, (i) {
        final filled = i < step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: filled ? palette.accent : palette.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
