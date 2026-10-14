import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/action_card.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/accessibility_shortcut_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/read_aloud_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final profile = context.watch<AuthState>().profile;
    final displayName = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : 'Kamala Fernando';
    return AppScaffold(
      routeName: Routes.home,
      scrollableBody: false,
      // Header is fixed and full-bleed behind the status bar; only the
      // content below it scrolls (see GreetingHeader).
      safeAreaTop: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingHeader(
            greeting: context.t('goodAfternoon'),
            name: displayName,
            actions: [
              ReadAloudButton(
                color: palette.onHero,
                summary: (t) => [
                  t('summaryPassengerHome'),
                  fillTemplate(t('summaryActions'), {
                    'actions':
                        '${t('planJourney')}, ${t('shareJourney')} '
                        '${t('summaryAnd')} ${t('reportCondition')}',
                  }),
                ].join(' '),
              ),
              AccessibilityShortcutButton(color: palette.onHero),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile == null) ...[
                      const DemoDataBadge(),
                      const SizedBox(height: 4),
                    ],
                    const DemoDataBadge(),
                    AlertBanner(
                      label: context.t('routeAlertLabel'),
                      message: 'Lift out of service at Fort Station, Platform 2 — reported 20 min ago',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ActionCard(
                            title: context.t('planJourney'),
                            description: context.t('planJourneyDesc'),
                            onTap: () =>
                                Navigator.of(context)
                                    .pushReplacementNamed(Routes.planSearch),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ActionCard(
                            title: context.t('shareJourney'),
                            description: context.t('shareJourneyDesc'),
                            onTap: () =>
                                Navigator.of(context)
                                    .pushReplacementNamed(Routes.shareSetup),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ActionCard(
                      title: context.t('reportCondition'),
                      description: context.t('reportConditionDescHome'),
                      onTap: () =>
                          Navigator.of(context)
                              .pushReplacementNamed(Routes.reportForm),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.t('recentActivity'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const DemoDataBadge(),
                    NoteCard(
                      child: const Text(
                        'Your journey to Bambalapitiya was shared with Nimal Perera on Aug 19',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
