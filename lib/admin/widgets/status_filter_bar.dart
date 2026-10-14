import 'package:flutter/material.dart';

import '../../widgets/chip_selector.dart';
import '../models/report_filter.dart';
import '../models/report_stats.dart';

/// Status filter chips: All / Under review / Accepted / Rejected, each with
/// its live count — the app's [SelectableChip], as used for the volunteer
/// feed and report-form pickers.
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in ReportFilter.values)
          // SelectableChip already announces its selected state.
          SelectableChip(
            label: '${filter.label} (${stats.countFor(filter)})',
            selected: filter == selected,
            onTap: () => onChanged(filter),
          ),
      ],
    );
  }
}
