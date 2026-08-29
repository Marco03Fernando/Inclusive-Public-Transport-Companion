import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';

/// The System / Light / Dark segmented switch shown on the profile screens.
/// Mirrors [LanguageToggle]'s shape, extended to three segments.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key, required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget seg(IconData icon, String label, ThemeMode value) {
      final active = mode == value;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? palette.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active ? [BoxShadow(color: palette.shadow, blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: active ? palette.cta : palette.muted),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: active ? palette.text : palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          seg(Icons.brightness_auto_rounded, context.t('themeSystem'), ThemeMode.system),
          const SizedBox(width: 4),
          seg(Icons.light_mode_rounded, context.t('themeLight'), ThemeMode.light),
          const SizedBox(width: 4),
          seg(Icons.dark_mode_rounded, context.t('themeDark'), ThemeMode.dark),
        ],
      ),
    );
  }
}
