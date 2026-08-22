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
import '../../widgets/labeled_text_field.dart';

class ReportFormScreen extends StatelessWidget {
  const ReportFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final origin = state.role == AppRole.passenger ? Routes.home : Routes.volunteerHome;

    Widget sectionLabel(String key) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            context.t(key),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
          ),
        );

    return AppScaffold(
      routeName: Routes.reportForm,
      title: context.t('reportCondition'),
      onBack: () => Navigator.of(context).pushReplacementNamed(origin),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionLabel('whatReporting'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: reportTargetOptions.map((tg) {
              return SelectableChip(
                label: context.t(tg.labelKey),
                selected: state.reportTargetId == tg.id,
                onTap: () => state.setReportTarget(tg.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('vehicleOrLocation'), initialValue: context.t('vehiclePlaceholder')),
          const SizedBox(height: 14),
          sectionLabel('conditionType'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: reportTypeOptions.map((rt) {
              return SelectableChip(
                label: context.t(rt.labelKey),
                selected: state.reportTypeId == rt.id,
                onTap: () => state.setReportType(rt.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          LabeledTextArea(label: context.t('description'), placeholder: context.t('descPlaceholder')),
          const SizedBox(height: 14),
          sectionLabel('photoOptional'),
          Container(
            width: double.infinity,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border, width: 1.5, style: BorderStyle.solid),
            ),
            child: Text(
              context.t('attachPhoto'),
              style: TextStyle(fontSize: 11, color: palette.muted, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: context.t('submitReport'),
            onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.reportConfirm),
          ),
        ],
      ),
    );
  }
}
