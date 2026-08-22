import 'package:flutter/material.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/condition_tile.dart';

class ReportMineScreen extends StatelessWidget {
  const ReportMineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      routeName: Routes.reportMine,
      title: context.t('myReportsTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.home),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final report in mockMyReports) ...[
            ConditionTile(report: report),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
