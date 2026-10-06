import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin/screens/admin_gate.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'my_reports_screen.dart';

/// App root: routes by the signed-in account's Firestore role.
///
///  - checking              → spinner
///  - signed out            → [LoginScreen]
///  - `role: "user"`        → [MyReportsScreen] (user home)
///  - `role: "admin"`       → [AdminGate] → admin dashboard
///
/// Normal users can never reach an admin screen: the admin module is only
/// ever built under this gate for an admin profile, [AdminGate] re-checks
/// the role, and the Firestore/Storage rules enforce it server-side.
///
/// Whenever the session or role changes, every pushed route is popped so
/// no screen from the previous session stays on top.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

enum _Destination { loading, login, user, admin }

class _AuthGateState extends State<AuthGate> {
  _Destination? _previous;

  @override
  Widget build(BuildContext context) {
    final destination = context.select<AuthProvider, _Destination>((auth) {
      switch (auth.status) {
        case AuthStatus.checking:
          return _Destination.loading;
        case AuthStatus.unauthenticated:
          return _Destination.login;
        case AuthStatus.authenticated:
          return auth.isAdmin ? _Destination.admin : _Destination.user;
      }
    });

    if (_previous != null && _previous != destination) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
    _previous = destination;

    switch (destination) {
      case _Destination.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case _Destination.login:
        return const LoginScreen();
      case _Destination.user:
        return const MyReportsScreen();
      case _Destination.admin:
        return const AdminGate();
    }
  }
}
