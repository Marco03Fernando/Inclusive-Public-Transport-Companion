import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/routes.dart';
import '../core/theme/app_theme.dart';

/// Header icon that opens Accessibility settings (text size, contrast,
/// Read Aloud). Pushed on top, so Back returns to the current screen.
class AccessibilityShortcutButton extends StatelessWidget {
  const AccessibilityShortcutButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.t('accessibilitySettings'),
      icon: Icon(
        Icons.accessibility_new_rounded,
        color: color ?? context.palette.text,
      ),
      onPressed: () =>
          Navigator.of(context).pushNamed(Routes.accessibilitySettings),
    );
  }
}
