import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/action_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/stat_card.dart';

class VolunteerHomeScreen extends StatelessWidget {
  const VolunteerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final profile = context.watch<AuthState>().profile;
    final displayName = (profile?.name.isNotEmpty ?? false) ? profile!.name : 'Ruwan Jayasuriya';
    return AppScaffold(
      routeName: Routes.volunteerHome,
      scrollableBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GreetingHeader(greeting: context.t('welcomeBack'), name: displayName),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (profile == null) ...[const DemoDataBadge(), const SizedBox(height: 4)],
                  const DemoDataBadge(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: StatCard(value: '14', label: context.t('reportsSubmitted'))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          value: '11',
                          label: context.t('verifiedByAdmin'),
                          valueColor: palette.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ActionCard(
                    title: context.t('reportCondition'),
                    description: context.t('volunteerReportDesc'),
                    onTap: () => Navigator.of(context).pushReplacementNamed(Routes.reportForm),
                  ),
                  const SizedBox(height: 12),
                  ActionCard(
                    title: context.t('communityReports'),
                    description: context.t('communityReportsDesc'),
                    onTap: () => Navigator.of(context).pushReplacementNamed(Routes.volunteerFeed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
