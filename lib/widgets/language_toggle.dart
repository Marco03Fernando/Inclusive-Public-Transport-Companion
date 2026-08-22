import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';

/// The EN / සිං segmented switch shown top-right on the role-select screen.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.locale, required this.onChanged});

  final AppLocale locale;
  final ValueChanged<AppLocale> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget seg(String label, AppLocale value) {
      final active = locale == value;
      return InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? palette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 2)]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? palette.text : palette.muted,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('EN', AppLocale.en),
          const SizedBox(width: 6),
          seg('සිං', AppLocale.si),
        ],
      ),
    );
  }
}
