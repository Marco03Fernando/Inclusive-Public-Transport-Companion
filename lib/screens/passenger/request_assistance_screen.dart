import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/assistance_request.dart';
import '../../services/assistance_request_service.dart';
import '../../services/location_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_selector.dart';
import '../../widgets/labeled_text_field.dart';

class RequestAssistanceScreen extends StatefulWidget {
  const RequestAssistanceScreen({super.key});

  @override
  State<RequestAssistanceScreen> createState() => _RequestAssistanceScreenState();
}

class _RequestAssistanceScreenState extends State<RequestAssistanceScreen> {
  final _requestService = AssistanceRequestService();
  final _locationService = LocationService();
  final _noteController = TextEditingController();

  AssistanceType _type = AssistanceType.boarding;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => _submitting = true);
    final authState = context.read<AuthState>();
    final position = await _locationService.getCurrentPosition();

    await _requestService.createRequest(AssistanceRequest(
      id: '',
      passengerUid: authState.uid!,
      passengerName: authState.profile?.name.isNotEmpty ?? false
          ? authState.profile!.name
          : authState.firebaseUser?.displayName ?? authState.firebaseUser?.email ?? 'Passenger',
      type: _type,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      status: AssistanceStatus.pending,
      lat: position?.latitude,
      lng: position?.longitude,
    ));

    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.requestStatus);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppScaffold(
      routeName: Routes.requestAssistance,
      title: context.t('requestAssistanceTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.profileHome),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('requestAssistanceIntro'),
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: 14),
          Text(
            context.t('requestTypeLabel'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AssistanceType.values.map((type) {
              return SelectableChip(
                label: context.t(assistanceTypeLabelKeys[type]!),
                selected: _type == type,
                onTap: () => setState(() => _type = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          LabeledTextArea(
            label: context.t('requestNoteLabel'),
            placeholder: context.t('requestNotePlaceholder'),
            controller: _noteController,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: _submitting ? context.t('loading') : context.t('submitRequest'),
            onPressed: _submitting ? null : () => _submit(context),
          ),
        ],
      ),
    );
  }
}
