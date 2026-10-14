import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin/screens/admin_gate.dart';
import '../core/state/app_state.dart';
import '../core/state/auth_state.dart';
import '../screens/onboarding/role_select_screen.dart';
import '../screens/passenger/home_screen.dart';
import '../screens/volunteer/volunteer_home_screen.dart';

/// Decides the very first screen once, at cold start, based on whether
/// Firebase already has a persisted session and that account's
/// `users/{uid}.role`. Every other transition in the app keeps navigating
/// explicitly via `Navigator.pushReplacementNamed` (see [Routes.homeFor]).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<AppRole?> _roleFuture = context.read<AuthState>().hydrateFromExistingSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppRole?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        switch (snapshot.data) {
          case AppRole.passenger:
            return const HomeScreen();
          case AppRole.volunteer:
            return const VolunteerHomeScreen();
          case AppRole.admin:
            return const AdminGate();
          case null:
            return const RoleSelectScreen();
        }
      },
    );
  }
}
