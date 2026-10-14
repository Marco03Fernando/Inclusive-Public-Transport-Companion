import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/report_filters.dart';

/// Subject, report type and sort controls for the admin report list. They
/// combine with the status tabs (see `AdminReportsProvider.query`).
///
/// Dropdowns rather than more chip rows, so the panel stays compact and
/// wraps cleanly at large text sizes; each one is labelled for screen
/// readers ("Subject, Buses").
class ReportFilterPanel extends StatelessWidget {
  const ReportFilterPanel({
    super.key,
    required this.subject,
    required this.type,
    required this.sort,
    required this.shown,
    required this.total,
    required this.onSubjectChanged,
    required this.onTypeChanged,
    required this.onSortChanged,
    this.onClear,
  });

  final SubjectFilter subject;
  final TypeFilter type;
  final ReportSort sort;

  /// Reports currently listed, and reports in total.
  final int shown;
  final int total;

  final ValueChanged<SubjectFilter> onSubjectChanged;
  final ValueChanged<TypeFilter> onTypeChanged;
  final ValueChanged<ReportSort> onSortChanged;

  /// Null hides "Clear filters" (nothing to clear).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        // Two per row on normal phones; one per row when space is tight.
        final perRow = constraints.maxWidth >= 360 && scale < 1.3 ? 2 : 1;
        final width = (constraints.maxWidth - 10 * (perRow - 1)) / perRow;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: _LabeledDropdown<SubjectFilter>(
                    label: 'Subject',
                    value: subject,
                    values: SubjectFilter.values,
                    labelOf: (v) => v.label,
                    onChanged: onSubjectChanged,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _LabeledDropdown<TypeFilter>(
                    label: 'Report type',
                    value: type,
                    values: TypeFilter.values,
                    labelOf: (v) => v.label,
                    onChanged: onTypeChanged,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _LabeledDropdown<ReportSort>(
                    label: 'Sort by',
                    value: sort,
                    values: ReportSort.values,
                    labelOf: (v) => v.label,
                    onChanged: onSortChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  // Announced politely whenever the result count changes.
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      'Showing $shown of $total reports',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
                if (onClear != null)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Clear filters'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DropdownButtonFormField<T>(
      // Keyed on the value so "Clear filters" resets what is displayed.
      key: ValueKey<Object?>(value),
      initialValue: value,
      isExpanded: true,
      dropdownColor: palette.surface,
      borderRadius: BorderRadius.circular(14),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: TextStyle(fontSize: 13.5, color: palette.text),
      items: [
        for (final v in values)
          DropdownMenuItem<T>(value: v, child: Text(labelOf(v))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
