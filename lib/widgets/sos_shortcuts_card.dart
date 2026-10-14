import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/locale.dart';
import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';
import '../services/sos_trigger_service.dart';
import 'toggle_row.dart';

/// Profile-screen section for the outside-the-app SOS shortcuts. Hidden on
/// platforms that don't support them.
class SosShortcutsCard extends StatelessWidget {
  const SosShortcutsCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SosTriggerService.instance.supported) return const SizedBox.shrink();
    final palette = context.palette;
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          context.t('sosShortcutsTitle'),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
        ),
        const SizedBox(height: 10),
        ToggleRow(
          title: context.t('volumeSosTitle'),
          subtitle: context.t('volumeSosNote'),
          value: state.volumeSosEnabled,
          onChanged: state.setVolumeSosEnabled,
        ),
        const SizedBox(height: 8),
        Text(
          context.t('sosShortcutsHint'),
          style: TextStyle(fontSize: 12, color: palette.muted, height: 1.5),
        ),
      ],
    );
  }
}
