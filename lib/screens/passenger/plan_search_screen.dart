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
import '../../models/route_request.dart';

class PlanSearchScreen extends StatefulWidget {
  const PlanSearchScreen({super.key});

  @override
  State<PlanSearchScreen> createState() => _PlanSearchScreenState();
}

class _PlanSearchScreenState extends State<PlanSearchScreen> {
  final TextEditingController _originController = TextEditingController();

  final TextEditingController _destinationController = TextEditingController();

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

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
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _originController,
                        decoration: const InputDecoration(
                          hintText: 'Enter starting point',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 14, color: palette.text),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 10, bottom: 10),
                  child: Container(height: 1, color: palette.border),
                ),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: palette.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          hintText: 'Enter destination',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 14, color: palette.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.t('routePreferences'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
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
            onPressed: () {
              final origin = _originController.text.trim();
              final destination = _destinationController.text.trim();

              if (origin.isEmpty || destination.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter both a starting point and destination.',
                    ),
                  ),
                );
                return;
              }

              Navigator.pushNamed(
                context,
                Routes.planResults,
                arguments: RouteRequest(
                  origin: origin,
                  destination: destination,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
