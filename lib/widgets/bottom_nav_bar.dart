import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/routes.dart';
import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';

const _tabIcons = {
  BottomTab.home: Icons.home_rounded,
  BottomTab.plan: Icons.alt_route_rounded,
  BottomTab.share: Icons.share_location_rounded,
  BottomTab.report: Icons.report_problem_rounded,
  BottomTab.reports: Icons.fact_check_rounded,
  BottomTab.profile: Icons.person_rounded,
};

const _tabLabelKeys = {
  BottomTab.home: 'navHome',
  BottomTab.plan: 'navPlan',
  BottomTab.share: 'navShare',
  BottomTab.report: 'navReport',
  BottomTab.reports: 'navReports',
  BottomTab.profile: 'navProfile',
};

/// Role-aware bottom tab bar. Active tab is derived from the current route
/// name against each [TabDef]'s match set, exactly like the design's
/// `bottomTabs` builder.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.role, required this.currentRoute});

  final AppRole role;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tabs = role == AppRole.passenger ? passengerTabs : volunteerTabs;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
        boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
          child: Row(
            children: tabs.map((tab) {
              final active = tab.matches.contains(currentRoute);
              final color = active ? palette.cta : palette.muted;
              return Expanded(
                child: InkWell(
                  onTap: active
                      ? null
                      : () => Navigator.of(context).pushReplacementNamed(tab.target),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? palette.ctaSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tabIcons[tab.tab], size: 22, color: color),
                        const SizedBox(height: 3),
                        Text(
                          context.t(_tabLabelKeys[tab.tab]!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
