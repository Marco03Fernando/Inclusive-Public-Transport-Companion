import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_selector.dart';

class PlanSearchScreen extends StatelessWidget {
  const PlanSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    return AppScaffold(
      routeName: Routes.planSearch,
      title: context.t('planJourney'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.home),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Nugegoda Bus Stand', style: TextStyle(fontSize: 14, color: palette.text)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 10, bottom: 10),
                  child: Container(height: 1, color: palette.border),
                ),
                Row(
                  children: [
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: palette.danger, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Bambalapitiya', style: TextStyle(fontSize: 14, color: palette.text)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.t('routePreferences'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: planFilterOptions.map((f) {
              return SelectableChip(
                label: context.t(f.labelKey),
                selected: state.planFilterIds.contains(f.id),
                onTap: () => state.togglePlanFilter(f.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: context.t('findRoutes'),
            onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.planResults),
          ),
        ],
      ),
    );
  }
}
