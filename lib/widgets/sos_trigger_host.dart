import 'package:flutter/material.dart';

import '../services/sos_trigger_service.dart';
import 'sos_dialog.dart';

/// Lets the root [MaterialApp] navigator open the SOS dialog when a trigger
/// arrives from outside the app (widget tap, volume presses).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Wrap the app's [MaterialApp.builder] child with this to listen for
/// external SOS triggers, including one that cold-started the app.
class SosTriggerHost extends StatefulWidget {
  const SosTriggerHost({super.key, required this.child});

  final Widget child;

  @override
  State<SosTriggerHost> createState() => _SosTriggerHostState();
}

class _SosTriggerHostState extends State<SosTriggerHost> {
  final _service = SosTriggerService.instance;

  @override
  void initState() {
    super.initState();
    _service
      ..onTrigger = _handleTrigger
      ..init();
    // Wait for the navigator to exist before asking for a cold-start trigger.
    WidgetsBinding.instance.addPostFrameCallback((_) => _service.drainPendingTrigger());
  }

  void _handleTrigger(String source) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleTrigger(source));
      return;
    }
    showSosDialog(context, immediate: true);
  }

  @override
  void dispose() {
    _service.onTrigger = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
