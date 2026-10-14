import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/locale.dart';
import '../core/state/accessibility_settings.dart';
import '../core/theme/app_theme.dart';
import '../services/read_aloud_service.dart';
import 'buttons.dart';
import 'read_aloud_button.dart';
import 'toggle_row.dart';

/// Spoken summary of the accessibility settings (current values only).
String accessibilitySummary(StringLookup t, AccessibilitySettings settings) =>
    fillTemplate(t('summaryAccessibility'), {
      'size': t(settings.textSize.labelKey),
      'contrast': t(settings.highContrast ? 'onWord' : 'offWord'),
    });

/// The "Accessibility" settings block: text size, High Contrast Mode, Read
/// Aloud and screen-reader guidance. Embedded in both profile screens and
/// shown on its own on [Routes.accessibilitySettings].
///
/// Every control writes straight to [AccessibilitySettings], which applies
/// app-wide and persists on the device.
class AccessibilitySettingsSection extends StatelessWidget {
  const AccessibilitySettingsSection({super.key, this.showTitle = true});

  /// False when the host screen's app bar already says "Accessibility".
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<AccessibilitySettings>();
    final reader = context.watch<ReadAloudService>();
    final screenReaderOn = MediaQuery.accessibleNavigationOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          _SectionTitle(context.t('accessibilityTitle'), large: true),
          const SizedBox(height: 4),
          Text(
            context.t('accessibilityIntro'),
            style: TextStyle(fontSize: 12, color: palette.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
        ],

        // ---- Text size ----
        _SectionTitle(context.t('textSize')),
        const SizedBox(height: 8),
        ChoiceSegments<TextSizePreset>(
          values: TextSizePreset.values,
          selected: settings.textSize,
          labelOf: (p) => context.t(p.labelKey),
          detailOf: (p) => '${p.percent}%',
          onChanged: settings.setTextSize,
        ),
        const SizedBox(height: 8),
        _InfoText(context.t('textSizeNote')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(12),
            border: palette.cardOutline,
          ),
          child: Text(
            context.t('textSizePreview'),
            style: TextStyle(fontSize: 14, color: palette.text, height: 1.4),
          ),
        ),
        const SizedBox(height: 18),

        // ---- High contrast ----
        ToggleRow(
          title: context.t('highContrastMode'),
          subtitle: context.t('highContrastNote'),
          value: settings.highContrast,
          onChanged: settings.setHighContrast,
        ),
        const SizedBox(height: 18),

        // ---- Read Aloud ----
        _SectionTitle(context.t('readAloudSection')),
        const SizedBox(height: 8),
        ToggleRow(
          title: context.t('readAloudToggle'),
          subtitle: context.t('readAloudToggleNote'),
          value: settings.readAloudEnabled,
          onChanged: settings.setReadAloudEnabled,
        ),
        const SizedBox(height: 12),
        Text(
          context.t('speechRate'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 8),
        ChoiceSegments<SpeechRate>(
          values: SpeechRate.values,
          selected: settings.speechRate,
          labelOf: (r) => context.t(r.labelKey),
          onChanged: settings.setSpeechRate,
        ),
        const SizedBox(height: 12),
        if (reader.isSpeaking)
          SecondaryButton(
            label: context.t('stopReading'),
            onPressed: reader.stop,
          )
        else
          SecondaryButton(
            label: context.t('readCurrentScreen'),
            onPressed: () => readScreenAloud(
              context,
              (t) => accessibilitySummary(t, settings),
            ),
          ),
        if (reader.canReplay && !reader.isSpeaking) ...[
          const SizedBox(height: 8),
          SecondaryButton(
            label: context.t('replayReading'),
            onPressed: () =>
                reader.replay(context, rate: settings.speechRate.rate),
          ),
        ],
        const SizedBox(height: 18),

        // ---- Screen reader guidance (information only) ----
        _SectionTitle(context.t('screenReaderSection')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: palette.cardOutline,
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('screenReaderNote'),
                style: TextStyle(
                  fontSize: 13,
                  color: palette.text,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              _GuideLine(context.t('talkbackGuide')),
              const SizedBox(height: 6),
              _GuideLine(context.t('voiceoverGuide')),
              if (screenReaderOn) ...[
                const SizedBox(height: 10),
                Text(
                  context.t('screenReaderActive'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Accessible single-choice segmented control: each segment is a button
/// announced with its label and "selected" state; segments wrap onto two
/// rows rather than clipping when text is large.
class ChoiceSegments<T> extends StatelessWidget {
  const ChoiceSegments({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.detailOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final String Function(T)? detailOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hc = palette.isHighContrast;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three per row normally; stack when large text would cramp them.
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final perRow = scale >= 1.4 || constraints.maxWidth < 300
            ? 1
            : values.length;
        final width = (constraints.maxWidth - 8 * (perRow - 1)) / perRow;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              SizedBox(
                width: width,
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  selected: value == selected,
                  button: true,
                  child: Material(
                    color: value == selected
                        ? palette.ctaSoft
                        : palette.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: value == selected ? palette.cta : palette.border,
                        width: value == selected ? 2 : (hc ? 1.5 : 1),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onChanged(value),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (value == selected) ...[
                                // Shape cue, so selection isn't colour-only.
                                ExcludeSemantics(
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: palette.cta,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  detailOf == null
                                      ? labelOf(value)
                                      : '${labelOf(value)} · ${detailOf!(value)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: value == selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: palette.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.large = false});

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: large ? 16 : 13,
          fontWeight: FontWeight.w700,
          color: context.palette.text,
        ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 12, color: context.palette.muted, height: 1.4),
  );
}

class _GuideLine extends StatelessWidget {
  const _GuideLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.accessibility_new_rounded,
              size: 16,
              color: palette.accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ),
      ],
    );
  }
}
