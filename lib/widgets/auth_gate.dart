import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin/providers/admin_auth_provider.dart';
import '../admin/screens/admin_gate.dart';
import '../core/state/accessibility_settings.dart';
import '../core/state/app_state.dart';
import '../core/state/auth_state.dart';
import '../screens/onboarding/role_select_screen.dart';
import '../screens/passenger/home_screen.dart';
import '../screens/volunteer/volunteer_home_screen.dart';
import '../services/firebase_bootstrap.dart';
import 'startup_splash.dart';

/// Decides the very first screen once, at cold start, based on whether
/// Firebase already has a persisted session and that account's
/// `users/{uid}.role`. Every other transition in the app keeps navigating
/// explicitly via `Navigator.pushReplacementNamed` (see [Routes.homeFor]).
///
/// While that work runs it shows [StartupSplash] — the only startup loading
/// screen — then fades straight to the right screen. There is no minimum
/// display time: the splash is replaced as soon as the work is done.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<AppRole?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _start();
  }

  /// Throws only if Firebase itself can't start (shown with a retry). A
  /// failed role lookup still lands on role select, as before.
  Future<AppRole?> _start() async {
    final appState = context.read<AppState>();
    final a11y = context.read<AccessibilitySettings>();
    // Local preferences load alongside Firebase (they're normally done
    // first), so the first screen opens in the saved theme / text size.
    await Future.wait([
      FirebaseBootstrap.ensureInitialized(),
      appState.ready,
      a11y.ready,
    ]);
    // AuthState builds on Firebase Auth, so it is only read from here on.
    if (!mounted) return null;
    final auth = context.read<AuthState>();
    final AppRole? role;
    try {
      role = await auth.hydrateFromExistingSession();
    } catch (_) {
      return null;
    }
    if (role == AppRole.admin) {
      // AdminGate independently re-verifies the role. Let that finish
      // behind this splash rather than following it with a second spinner.
      if (!mounted) return role;
      await _adminCheckSettled(context.read<AdminAuthProvider>());
    }
    return role;
  }

  static Future<void> _adminCheckSettled(AdminAuthProvider admin) {
    if (admin.status != AdminAuthStatus.checking) return Future.value();
    final settled = Completer<void>();
    void onChange() {
      if (admin.status == AdminAuthStatus.checking) return;
      admin.removeListener(onChange);
      if (!settled.isCompleted) settled.complete();
    }

    admin.addListener(onChange);
    return settled.future;
  }

  void _retry() => setState(() => _roleFuture = _start());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppRole?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        // Same key while loading / failed, so the splash stays mounted (and
        // its fade never replays) across a failure and retry.
        const splashKey = ValueKey('startup-splash');
        final Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const StartupSplash(key: splashKey);
        } else if (snapshot.hasError) {
          child = StartupSplash(key: splashKey, failed: true, onRetry: _retry);
        } else {
          child = switch (snapshot.data) {
            AppRole.passenger => const HomeScreen(),
            AppRole.volunteer => const VolunteerHomeScreen(),
            AppRole.admin => const AdminGate(),
            null => const RoleSelectScreen(),
          };
        }
        return AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: child,
        );
      },
    );
  }
}
