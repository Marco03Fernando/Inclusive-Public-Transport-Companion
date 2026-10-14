import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/localization/locale.dart';

/// What happened when a screen summary was requested.
enum ReadAloudResult {
  /// Spoken by the device's text-to-speech engine in the app language.
  spoken,

  /// The app language has no installed voice, so the English summary was
  /// spoken instead.
  spokenInEnglish,

  /// TalkBack / VoiceOver is running, so the summary was handed to it as an
  /// announcement instead of starting a second, overlapping voice.
  announcedByScreenReader,

  /// No usable text-to-speech engine/voice on this device.
  unavailable,
}

/// Looks up a localized string by key (same keys as `context.t`).
typedef StringLookup = String Function(String key);

/// Builds a screen's spoken summary from a string lookup, so the same
/// summary can be produced in English when the app language has no voice
/// (or no translation for part of the summary).
typedef ScreenSummaryBuilder = String Function(StringLookup t);

/// Optional "Read aloud" for users who don't use TalkBack/VoiceOver.
///
/// Wraps the device's own text-to-speech engine via `flutter_tts` (system
/// voices only — no network or paid API). Only ever speaks in response to
/// an explicit user action; never on navigation.
///
/// - One utterance at a time: every new [readSummary] stops the previous
///   one first, so sessions can't overlap.
/// - [replay] repeats the last summary; [stop] silences it.
/// - When a screen reader is active the summary is sent through
///   [SemanticsService] instead, so the user's screen reader voice says it
///   and the two voices never talk over each other.
class ReadAloudService extends ChangeNotifier {
  ReadAloudService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;
  bool _engineAvailable = true;
  bool _isSpeaking = false;
  bool _disposed = false;

  String? _lastText;
  String? _lastLanguage;

  /// Stops speech when the user navigates, so a summary of the previous
  /// screen never keeps talking over the new one. Install once in
  /// `MaterialApp.navigatorObservers` (same instance on every build).
  late final NavigatorObserver navigatorObserver = _StopOnNavigation(this);

  bool get isSpeaking => _isSpeaking;
  bool get canReplay => _lastText != null;

  static const _englishVoice = 'en-US';
  static const _sinhalaVoice = 'si-LK';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _tts
        ..setStartHandler(() => _setSpeaking(true))
        ..setCompletionHandler(() => _setSpeaking(false))
        ..setCancelHandler(() => _setSpeaking(false))
        ..setErrorHandler((message) {
          _log('TTS error: $message');
          _setSpeaking(false);
        });
      // speak() returns as soon as speech is queued; the handlers above
      // track when it actually starts and ends.
      await _tts.awaitSpeakCompletion(false);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // Play even with the silent switch on, mixing politely with audio.
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ]);
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final engine = await _tts.getDefaultEngine;
        _engineAvailable = engine != null && '$engine'.isNotEmpty;
      }
    } catch (e) {
      _log('TTS init failed: $e');
      _engineAvailable = false;
    }
  }

  /// Speaks (or announces) the summary for the current screen.
  ///
  /// [context] is used only to detect an active screen reader and the
  /// text direction; [locale] picks the language.
  Future<ReadAloudResult> readSummary(
    BuildContext context, {
    required AppLocale locale,
    required ScreenSummaryBuilder summary,
    required double rate,
  }) async {
    final screenReaderOn =
        MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final view = View.maybeOf(context);

    if (screenReaderOn && view != null) {
      await stop();
      final text = summary(
        (key) => AppStrings.forLocale(locale)[key] ?? AppStrings.en[key] ?? key,
      );
      _lastText = text;
      _lastLanguage = null;
      await SemanticsService.sendAnnouncement(view, text, textDirection);
      notifyListeners();
      return ReadAloudResult.announcedByScreenReader;
    }

    await _ensureInitialized();
    if (!_engineAvailable) return ReadAloudResult.unavailable;

    String english(String key) => AppStrings.en[key] ?? key;

    var result = ReadAloudResult.spoken;
    var language = _englishVoice;
    var text = '';

    if (locale == AppLocale.si) {
      // Use Sinhala only if a Sinhala voice is installed AND every string
      // in the summary is translated; otherwise say it all in English
      // rather than reading mixed text with the wrong voice.
      var complete = true;
      final sinhala = summary((key) {
        final value = AppStrings.si[key];
        if (value == null) complete = false;
        return value ?? english(key);
      });
      if (complete && await _isLanguageAvailable(_sinhalaVoice)) {
        language = _sinhalaVoice;
        text = sinhala;
      } else {
        result = ReadAloudResult.spokenInEnglish;
      }
    }

    if (language == _englishVoice) {
      if (!await _isLanguageAvailable(_englishVoice)) {
        return ReadAloudResult.unavailable;
      }
      text = summary(english);
    }

    final spoke = await _speak(text, language: language, rate: rate);
    return spoke ? result : ReadAloudResult.unavailable;
  }

  /// Repeats the last summary (no-op if nothing has been read yet).
  Future<ReadAloudResult> replay(BuildContext context, {required double rate}) {
    final text = _lastText;
    if (text == null) return Future.value(ReadAloudResult.unavailable);
    return readSummary(
      context,
      locale: _lastLanguage == _sinhalaVoice ? AppLocale.si : AppLocale.en,
      summary: (_) => text,
      rate: rate,
    );
  }

  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _tts.stop();
    } catch (e) {
      _log('TTS stop failed: $e');
    }
    _setSpeaking(false);
  }

  Future<bool> _speak(
    String text, {
    required String language,
    required double rate,
  }) async {
    try {
      await _tts.stop(); // never overlap two sessions
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(rate);
      _lastText = text;
      _lastLanguage = language;
      _setSpeaking(true);
      final status = await _tts.speak(text);
      if (status != 1) _setSpeaking(false);
      return status == 1;
    } catch (e) {
      _log('TTS speak failed: $e');
      _setSpeaking(false);
      return false;
    }
  }

  Future<bool> _isLanguageAvailable(String language) async {
    try {
      final available = await _tts.isLanguageAvailable(language);
      return available == true || available == 1;
    } catch (e) {
      _log('TTS language check failed for $language: $e');
      return false;
    }
  }

  void _setSpeaking(bool value) {
    if (_disposed || _isSpeaking == value) return;
    _isSpeaking = value;
    notifyListeners();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ReadAloud] $message');
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_tts.stop().catchError((_) => null));
    super.dispose();
  }
}

class _StopOnNavigation extends NavigatorObserver {
  _StopOnNavigation(this._service);

  final ReadAloudService _service;

  void _stop() {
    if (_service.isSpeaking) unawaited(_service.stop());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _stop();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _stop();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _stop();
}
