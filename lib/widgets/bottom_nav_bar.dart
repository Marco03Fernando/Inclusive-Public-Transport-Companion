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
  const AppBottomNavBar({
    super.key,
    required this.role,
    required this.currentRoute,
  });

  final AppRole role;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tabs = role == AppRole.passenger ? passengerTabs : volunteerTabs;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(
            color: palette.isHighContrast ? palette.cardBorder : palette.border,
            width: palette.isHighContrast ? 1.5 : 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tab in tabs)
                Expanded(
                  child: _NavItem(
                    icon: _tabIcons[tab.tab]!,
                    label: context.t(_tabLabelKeys[tab.tab]!),
                    active: tab.matches.contains(currentRoute),
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed(tab.target),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One destination: an icon in a pill indicator (filled when selected) and
/// a label underneath. Announced as "Home, selected, button"; tapping the
/// current tab does nothing (but stays enabled, so it isn't announced as
/// "disabled").
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hc = palette.isHighContrast;
    final color = active ? (hc ? palette.text : palette.cta) : palette.muted;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      onTap: active ? () {} : onTap,
      child: InkWell(
        onTap: active ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 30,
                  decoration: BoxDecoration(
                    color: active ? palette.ctaSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    // Outline as a non-colour selection cue in high contrast.
                    border: active && hc
                        ? Border.all(color: palette.text, width: 1.5)
                        : null,
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.15,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? palette.text : palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
