import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../providers/admin_auth_provider.dart';
import '../widgets/admin_message_state.dart';
import 'admin_dashboard_screen.dart';

/// The single door into the admin screens (route [Routes.admin]).
///
/// `AuthGate` / the login screen only route here when the signed-in
/// profile has `role: "admin"`; this gate re-verifies that independently:
///  - still checking        → spinner
///  - not a verified admin  → "no admin access" + sign out
///  - verified admin        → [AdminDashboardScreen]
///
/// If the session ends while deeper screens (list / details) are open —
/// sign-out, expired or revoked account — everything above the gate is
/// popped so no admin screen stays visible.
///
/// NOTE: this is the UX gate. The real protection is the Firestore
/// security rules, which refuse non-admins the data regardless of what
/// the app shows.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AdminAuthProvider, AdminAuthStatus>(
      (auth) => auth.status,
    );

    switch (status) {
      case AdminAuthStatus.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case AdminAuthStatus.unauthenticated:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
        return Scaffold(
          body: SafeArea(
            child: AdminMessageState(
              icon: Icons.lock_outline,
              title: 'No admin access',
              message: 'This account does not have admin access.',
              actionLabel: 'SIGN OUT',
              onAction: () async {
                await context.read<AuthState>().signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(Routes.roleSelect, (route) => false);
              },
            ),
          ),
        );

      case AdminAuthStatus.authenticated:
        return const AdminDashboardScreen();
    }
  }
}
