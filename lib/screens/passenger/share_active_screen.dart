import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/map_placeholder.dart';

class ShareActiveScreen extends StatelessWidget {
  const ShareActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    return AppScaffold(
      routeName: Routes.shareActive,
      title: context.t('journeyInProgress'),
      scrollableBody: false,
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.home),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MapPlaceholder(label: context.t('mapLivePosition'), height: 150),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DemoDataBadge(),
                  SuccessBanner(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: palette.text),
                        children: [
                          const TextSpan(text: 'Nimal Perera ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '${context.t('notifiedStarted')} '),
                          TextSpan(text: state.elapsedLabel, style: const TextStyle(fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'On Bus 138, next stop Bambalapitiya Junction in ~6 min',
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                  const SizedBox(height: 28),
                  DangerButton(
                    label: context.t('endJourney'),
                    onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.home),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
