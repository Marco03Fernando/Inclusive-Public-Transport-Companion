import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/report_filter.dart';
import '../models/report_stats.dart';

/// Horizontally scrolling status tabs: All / Under review / Accepted /
/// Rejected, each with its live count. Selected tab uses the same
/// black-filled style as the user side's `ChoiceTileButton`.
class StatusFilterBar extends StatelessWidget {
  final ReportFilter selected;
  final ReportStats stats;
  final ValueChanged<ReportFilter> onChanged;

  const StatusFilterBar({
    super.key,
    required this.selected,
    required this.stats,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const filters = ReportFilter.values;

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selected;
          final text = '${filter.label} (${stats.countFor(filter)})';

          return Semantics(
            button: true,
            selected: isSelected,
            label: 'Show ${filter.label} reports, ${stats.countFor(filter)}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onChanged(filter),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.black,
                    width: isSelected ? 2 : 1.3,
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
