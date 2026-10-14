import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the Android-only SOS shortcuts (home-screen widget, volume
/// presses). Everything degrades to a no-op on other platforms.
class SosTriggerService {
  SosTriggerService._();
  static final instance = SosTriggerService._();

  static const _channel = MethodChannel('colombo_pal/sos');

  /// Called with the trigger source ("widget", "volume").
  void Function(String source)? onTrigger;

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void init() {
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sosPending') await drainPendingTrigger();
    });
  }

  /// Picks up a trigger that launched or re-focused the app, if any.
  Future<void> drainPendingTrigger() async {
    final source = await _call<String>('consumeLaunchTrigger');
    if (source != null) onTrigger?.call(source);
  }

  Future<bool> isVolumeTriggerEnabled() async =>
      await _call<bool>('isVolumeTriggerEnabled') ?? false;

  Future<bool> setVolumeTriggerEnabled(bool enabled) async =>
      await _call<bool>('setVolumeTriggerEnabled', {'enabled': enabled}) ?? false;

  Future<T?> _call<T>(String method, [Object? args]) async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
