import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Starts Firebase once. `main()` kicks it off before the first frame and
/// `AuthGate` awaits it behind the startup splash, so the branded screen is
/// visible while Firebase starts instead of a blank native window.
///
/// Every Firebase-backed provider in `app.dart` is created lazily and first
/// read below `AuthGate`, i.e. only after this has completed.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void>? _pending;

  /// Completes when Firebase is ready. A failed attempt is forgotten, so
  /// calling this again (the splash's "Try again") retries it.
  static Future<void> ensureInitialized() async {
    final pending = _pending ??= _initialize();
    try {
      await pending;
    } catch (_) {
      if (identical(_pending, pending)) _pending = null;
      rethrow;
    }
  }

  static Future<void> _initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // Hot restart on Android can find the native default app already set up.
      if (e.code != 'duplicate-app') rethrow;
    }
    if (kDebugMode) {
      // TEMP DEBUG (condition-report Storage 404): which Firebase project /
      // bucket the running app really uses. Remove once uploads are verified.
      final options = Firebase.app().options;
      debugPrint(
        '[Firebase] projectId=${options.projectId} storageBucket=${options.storageBucket} '
        'appId=${options.appId}',
      );
    }
  }
}
