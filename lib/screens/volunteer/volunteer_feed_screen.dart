import 'package:flutter/material.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/chip_selector.dart';
import '../../widgets/condition_tile.dart';
import '../../widgets/demo_data_badge.dart';

class VolunteerFeedScreen extends StatefulWidget {
  const VolunteerFeedScreen({super.key});

  @override
  State<VolunteerFeedScreen> createState() => _VolunteerFeedScreenState();
}

class _VolunteerFeedScreenState extends State<VolunteerFeedScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final labels = [context.t('allFilter'), context.t('busesFilter'), context.t('stationsFilter')];
    return AppScaffold(
      routeName: Routes.volunteerFeed,
      title: context.t('communityReports'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.volunteerHome),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: List.generate(labels.length, (i) {
              return SelectableChip(
                label: labels[i],
                selected: _filter == i,
                onTap: () => setState(() => _filter = i),
              );
            }),
          ),
          const SizedBox(height: 12),
          const DemoDataBadge(),
          for (final item in mockVolunteerFeed) ...[
            ConditionTile(report: item),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
