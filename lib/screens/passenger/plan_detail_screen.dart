import 'package:flutter/material.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/condition_tile.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/map_placeholder.dart';
import '../../widgets/route_step_item.dart';

class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppScaffold(
      routeName: Routes.planDetail,
      title: 'Bus 138 + Coastal Line',
      scrollableBody: false,
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.planResults),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MapPlaceholder(label: context.t('mapLiveRoute'), height: 160, showRoute: true),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t('stepByStep'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
                  ),
                  const SizedBox(height: 10),
                  const DemoDataBadge(),
                  for (var i = 0; i < mockRouteSteps.length; i++)
                    RouteStepItem(step: mockRouteSteps[i], isLast: i == mockRouteSteps.length - 1),
                  const SizedBox(height: 4),
                  Text(
                    context.t('reportedAlongRoute'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
                  ),
                  const SizedBox(height: 10),
                  const DemoDataBadge(),
                  for (final c in mockRouteConditions) ...[
                    ConditionTile(report: c),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
