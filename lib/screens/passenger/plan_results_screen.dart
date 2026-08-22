import 'package:flutter/material.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/route_option_card.dart';

class PlanResultsScreen extends StatelessWidget {
  const PlanResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppScaffold(
      routeName: Routes.planResults,
      title: context.t('routeOptionsTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.planSearch),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nugegoda Bus Stand → Bambalapitiya · ${mockRouteOptions.length} routes found',
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          const SizedBox(height: 12),
          for (final option in mockRouteOptions) ...[
            RouteOptionCard(
              option: option,
              onTap: () => Navigator.of(context).pushReplacementNamed(Routes.planDetail),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
