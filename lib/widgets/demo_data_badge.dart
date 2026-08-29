import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';

/// Small "Demo data" flag shown above lists backed by [lib/data/mock_data.dart]
/// fixtures instead of a real backend. Debug-only (via [kDebugMode]) so it
/// never reaches a release build — it exists purely so developers/testers
/// can tell placeholder content from the genuine article at a glance.
class DemoDataBadge extends StatelessWidget {
  const DemoDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border, width: 1, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.data_object_rounded, size: 12, color: palette.muted),
            const SizedBox(width: 5),
            Text(
              context.t('demoDataLabel'),
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.muted, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
