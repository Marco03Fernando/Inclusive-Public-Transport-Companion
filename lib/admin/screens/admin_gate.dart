import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../widgets/buttons.dart';
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
    // Also rebuild when a failed role check's message changes.
    context.select<AdminAuthProvider, String?>((auth) => auth.error);

    switch (status) {
      case AdminAuthStatus.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AdminAuthStatus.unauthenticated:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
        final auth = context.read<AdminAuthProvider>();
        final checkFailed = auth.error != null;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AdminMessageState(
                    icon: checkFailed
                        ? Icons.cloud_off_outlined
                        : Icons.lock_outline,
                    title: checkFailed
                        ? 'Could not verify admin access'
                        : 'No admin access',
                    message:
                        auth.error ??
                        'This account does not have admin access.',
                    actionLabel: checkFailed ? 'Try again' : null,
                    onAction: checkFailed ? auth.retry : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextDangerButton(
                    label: 'Log out',
                    onPressed: () async {
                      await context.read<AuthState>().signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.roleSelect,
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );

      case AdminAuthStatus.authenticated:
        return const AdminDashboardScreen();
    }
  }
}
