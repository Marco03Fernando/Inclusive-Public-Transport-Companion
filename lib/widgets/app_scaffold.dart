import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/state/app_state.dart';
import 'bottom_nav_bar.dart';
import 'screen_header.dart';
import 'sos_button.dart';
import 'sos_dialog.dart';

/// Shared screen shell: optional [ScreenHeader] app bar, the role-aware
/// bottom nav bar, and the floating SOS button — all gated per-route by
/// [Routes.showsBottomNav] / [Routes.showsSos], matching the design's
/// per-screen `showBottomNav` / `showSosButton` flags.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.routeName,
    required this.body,
    this.title,
    this.onBack,
    this.scrollableBody = true,
  });

  final String routeName;
  final Widget body;
  final String? title;
  final VoidCallback? onBack;

  /// Wrap [body] in padding + scroll view. Set false when the screen needs
  /// full control (e.g. a header image that must touch the top edge).
  final bool scrollableBody;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppState>().role;
    final showNav = Routes.showsBottomNav(routeName);
    final showSos = Routes.showsSos(routeName, role);

    Widget content = body;
    if (scrollableBody) {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [body]),
      );
    }

    return Scaffold(
      appBar: title != null ? ScreenHeader(title: title!, onBack: onBack) : null,
      body: SafeArea(child: content),
      bottomNavigationBar: showNav ? AppBottomNavBar(role: role, currentRoute: routeName) : null,
      floatingActionButton: showSos ? SosButton(onPressed: () => showSosDialog(context)) : null,
    );
  }
}
