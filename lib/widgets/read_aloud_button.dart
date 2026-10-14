import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/locale.dart';
import '../core/state/accessibility_settings.dart';
import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';
import '../services/read_aloud_service.dart';

/// Reads [summary] aloud (or stops reading if already speaking), then tells
/// the user — in a SnackBar — if the voice fell back to English or isn't
/// available. Shared by [ReadAloudButton] and the accessibility settings.
Future<void> readScreenAloud(
  BuildContext context,
  ScreenSummaryBuilder summary,
) async {
  final service = context.read<ReadAloudService>();
  final locale = context.read<AppState>().locale;
  final rate = context.read<AccessibilitySettings>().speechRate.rate;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final englishFallback = context.t('readAloudEnglishFallback');
  final unavailable = context.t('readAloudUnavailable');

  final result = await service.readSummary(
    context,
    locale: locale,
    summary: summary,
    rate: rate,
  );

  final message = switch (result) {
    ReadAloudResult.spokenInEnglish => englishFallback,
    ReadAloudResult.unavailable => unavailable,
    ReadAloudResult.spoken || ReadAloudResult.announcedByScreenReader => null,
  };
  if (message != null) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Speaker button that reads a short summary of the current screen.
///
/// Hidden when the user has turned "Show Read Aloud buttons" off. Becomes
/// a stop button while speech is playing. Nothing is spoken unless the
/// user taps it.
class ReadAloudButton extends StatelessWidget {
  const ReadAloudButton({super.key, required this.summary, this.color});

  final ScreenSummaryBuilder summary;

  /// Icon colour; defaults to the theme text colour. Pass the hero
  /// foreground when placed on a dashboard header.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<AccessibilitySettings, bool>(
      (s) => s.readAloudEnabled,
    );
    if (!enabled) return const SizedBox.shrink();

    final service = context.watch<ReadAloudService>();
    final speaking = service.isSpeaking;
    final label = context.t(speaking ? 'stopReading' : 'readAloud');

    return IconButton(
      tooltip: label,
      // 48x48 minimum touch target comes from IconButton's defaults.
      icon: Icon(
        speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        color: color ?? context.palette.text,
      ),
      onPressed: () =>
          speaking ? service.stop() : readScreenAloud(context, summary),
    );
  }
}
