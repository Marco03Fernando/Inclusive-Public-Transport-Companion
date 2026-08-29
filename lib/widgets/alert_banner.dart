import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The amber route-alert banner on Home ("Lift out of service...").
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.label, required this.message});

  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.warnSoft,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: palette.warn.withValues(alpha: 0.16), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: palette.text),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: message),
          ],
        ),
      ),
    );
  }
}

/// The green "notified" banner on the active-share screen.
class SuccessBanner extends StatelessWidget {
  const SuccessBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.successSoft,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: palette.success.withValues(alpha: 0.16), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: DefaultTextStyle(style: TextStyle(fontSize: 13, color: palette.text), child: child),
    );
  }
}

/// A plain elevated note card (recent activity, journey summary, sharing
/// history rows).
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.child, this.tint});

  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: tint ?? palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: tint == null ? [BoxShadow(color: palette.shadow, blurRadius: 12, offset: const Offset(0, 5))] : null,
      ),
      child: DefaultTextStyle(style: TextStyle(fontSize: 13, color: palette.text), child: child),
    );
  }
}
