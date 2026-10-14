import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/accessibility_settings.dart';
import '../../widgets/accessibility_settings_section.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/read_aloud_button.dart';

/// Stand-alone Accessibility settings, opened from the dashboard header
/// shortcut. Same controls as the Accessibility section on the profile
/// screens ([AccessibilitySettingsSection]); pushed on top, so Back
/// returns to wherever the user came from.
class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AccessibilitySettings>();
    return AppScaffold(
      routeName: Routes.accessibilitySettings,
      title: context.t('accessibilitySettings'),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        ReadAloudButton(summary: (t) => accessibilitySummary(t, settings)),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('accessibilityIntro'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          const AccessibilitySettingsSection(showTitle: false),
        ],
      ),
    );
  }
}
