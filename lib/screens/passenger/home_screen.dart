import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessibility_shortcut_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/home_widgets.dart';
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      routeName: Routes.home,
      scrollableBody: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeTopBar(
              actions: [
                ReadAloudButton(
                  color: palette.accent,
                  summary: (t) => [
                    t('summaryPassengerHome'),
                    fillTemplate(t('summaryActions'), {
                      'actions':
                          '${t('planJourney')}, ${t('shareJourney')} '
                          '${t('summaryAnd')} ${t('reportCondition')}',
                    }),
                  ].join(' '),
                ),
                AccessibilityShortcutButton(color: palette.accent),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeWelcomeCard(
                        greeting: context.t('goodAfternoon'),
                        name: displayName,
                        prompt: context.t('homeWhereTo'),
                      ),
                      const SizedBox(height: 18),
                      HomeAlertCard(
                        label: context.t('routeAlertLabel'),
                        message: 'Lift out of service at Fort Station, Platform 2 — reported 20 min ago',
                      ),
                      const SizedBox(height: 20),
                      HomeFeatureCard(
                        title: context.t('planJourney'),
                        description: context.t('planJourneyDesc'),
                        icon: Icons.alt_route_rounded,
                        onTap: () =>
                            Navigator.of(context)
                                .pushReplacementNamed(Routes.planSearch),
                      ),
                      const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: HomeActionTile(
                                title: context.t('shareJourney'),
                                description: context.t('shareJourneyDesc'),
                                icon: Icons.share_location_rounded,
                                tone: HomeTileTone.success,
                                onTap: () => Navigator.of(context)
                                    .pushReplacementNamed(Routes.shareSetup),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: HomeActionTile(
                                title: context.t('reportCondition'),
                                description: context.t(
                                  'reportConditionDescHome',
                                ),
                                icon: Icons.report_problem_rounded,
                                tone: HomeTileTone.cta,
                                onTap: () => Navigator.of(context)
                                    .pushReplacementNamed(Routes.reportForm),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      HomeFeatureCard(
                        title: context.t('requestAssistanceTitle'),
                        description: context.t('requestAssistanceHomeDesc'),
                        icon: Icons.support_agent_rounded,
                        imageAsset: 'assets/artwork/care_support_icon.png',
                        onTap: () =>
                            Navigator.of(context)
                                .pushReplacementNamed(Routes.requestAssistance),
                      ),
                      const SizedBox(height: 14),
                      HomeExploreBanner(
                        title: context.t('exploreColomboTitle'),
                        description: context.t('exploreColomboDesc'),
                        onTap: () => Navigator.of(
                          context,
                        ).pushReplacementNamed(Routes.planSearch),
                      ),
                      const SizedBox(height: 28),
                      HomeSectionTitle(context.t('recentActivity')),
                      const SizedBox(height: 12),
                      const HomeActivityCard(
                        icon: Icons.share_location_rounded,
                        child: Text(
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
      ),
    );
  }
}
