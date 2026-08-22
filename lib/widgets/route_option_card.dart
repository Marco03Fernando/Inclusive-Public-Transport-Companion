import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';
import '../models/route_option.dart';
import 'status_badge.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({super.key, required this.option, required this.onTap});

  final RouteOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final high = option.accessScore == AccessScore.high;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    option.mode,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: palette.text),
                  ),
                ),
                AccessScoreBadge(
                  label: '${high ? 'High' : 'Medium'} ${context.t('accessSuffix')}',
                  high: high,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(option.duration, style: TextStyle(fontSize: 12, color: palette.muted)),
                const SizedBox(width: 14),
                Text('${option.transfers} transfer(s)', style: TextStyle(fontSize: 12, color: palette.muted)),
                const SizedBox(width: 14),
                Text('${option.crowding} crowding', style: TextStyle(fontSize: 12, color: palette.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
