import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/condition_report.dart';
import '../../providers/reports_provider.dart';
import '../../services/location_service.dart';
import '../../services/photo_service.dart';
import '../../utils/validators.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_selector.dart';
import '../../widgets/labeled_text_field.dart';

/// "Report Condition": collects subject, vehicle/station number, GPS
/// location, condition type, description and an optional photo, then
/// submits through [ReportsProvider] → `ConditionReportService` →
/// Firestore `condition_reports` (+ Storage for the photo).
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _draft = ConditionReportDraft();
  final _vehicleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationService = LocationService();
  final _photoService = PhotoService();

  String? _subjectError;
  String? _vehicleError;
  String? _locationError;
  String? _conditionError;
  String? _descriptionError;
  bool _isLocating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _draft.reportLocation = location;
        _draft.location = location.label;
        _locationController.text = location.label;
      });
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.message);
      if (e.permanentlyDenied) await _offerAppSettings();
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationError = 'Could not get your location. Please try again.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _offerAppSettings() async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location permission required'),
        content: const Text(
          'Location permission has been permanently denied. '
          'Please enable location permission from the app settings.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('OPEN SETTINGS')),
        ],
      ),
    );
    if (openSettings == true) await _locationService.openAppSettings();
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.t('takePhoto')),
              onTap: () => Navigator.of(ctx).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.t('chooseFromGallery')),
              onTap: () => Navigator.of(ctx).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final path = await _photoService.pickPhoto(source);
      if (path == null || !mounted) return; // user cancelled the picker
      setState(() => _draft.photoPath = path);
    } on PhotoServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  bool _validate() {
    setState(() {
      _subjectError = ReportValidators.subject(_draft.subject);
      _vehicleError = ReportValidators.vehicleOrStationNumber(_vehicleController.text, _draft.subject);
      _locationError = ReportValidators.location(_locationController.text);
      _conditionError = ReportValidators.conditionType(_draft.conditionType);
      _descriptionError = ReportValidators.description(_descriptionController.text);
    });
    return _subjectError == null &&
        _vehicleError == null &&
        _locationError == null &&
        _conditionError == null &&
        _descriptionError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    _draft
      ..vehicleOrStationNumber = _vehicleController.text.trim()
      ..location = _locationController.text.trim()
      ..description = _descriptionController.text.trim();

    setState(() => _isSubmitting = true);
    final provider = context.read<ReportsProvider>();
    final success = await provider.submitReport(ConditionReport.fromDraft(_draft));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not submit your report.')),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed(Routes.reportConfirm);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final role = context.watch<AppState>().role;

    Widget sectionLabel(String key) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            context.t(key),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
          ),
        );

    Widget fieldError(String? message) => message == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(message, style: TextStyle(fontSize: 12, color: palette.danger)),
          );

    return AppScaffold(
      routeName: Routes.reportForm,
      title: context.t('reportCondition'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.homeFor(role)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionLabel('whatReporting'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportSubject.values.map((subject) {
              return SelectableChip(
                label: context.t(subject.labelKey),
                selected: _draft.subject == subject,
                onTap: () => setState(() {
                  _draft.subject = subject;
                  _subjectError = null;
                }),
              );
            }).toList(),
          ),
          fieldError(_subjectError),
          const SizedBox(height: 14),
          LabeledTextField(
            label: context.t('vehicleOrLocation'),
            initialValue: context.t('vehiclePlaceholder'),
            controller: _vehicleController,
            textCapitalization: TextCapitalization.characters,
            errorText: _vehicleError,
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: context.t('locationLabel'),
            initialValue: context.t('useCurrentLocation'),
            controller: _locationController,
            readOnly: true,
            onTap: _isLocating ? null : _useCurrentLocation,
            errorText: _locationError,
            suffixIcon: _isLocating
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    tooltip: context.t('useCurrentLocation'),
                    icon: const Icon(Icons.my_location, size: 20),
                    onPressed: _useCurrentLocation,
                  ),
          ),
          const SizedBox(height: 14),
          sectionLabel('conditionType'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ConditionType.values.map((type) {
              return SelectableChip(
                label: context.t(type.labelKey),
                selected: _draft.conditionType == type,
                onTap: () => setState(() {
                  _draft.conditionType = type;
                  _conditionError = null;
                }),
              );
            }).toList(),
          ),
          fieldError(_conditionError),
          const SizedBox(height: 14),
          LabeledTextArea(
            label: context.t('description'),
            placeholder: context.t('descPlaceholder'),
            controller: _descriptionController,
            errorText: _descriptionError,
          ),
          const SizedBox(height: 14),
          sectionLabel('photoOptional'),
          _PhotoPicker(photoPath: _draft.photoPath, onTap: _choosePhoto),
          const SizedBox(height: 28),
          PrimaryButton(
            label: _isSubmitting ? context.t('loading') : context.t('submitReport'),
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoPath, required this.onTap});

  final String? photoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasPhoto = photoPath != null;

    return Semantics(
      button: true,
      label: hasPhoto ? 'Photo added, tap to replace' : 'Tap to add photo',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: hasPhoto ? 160 : 90,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border, width: 1.5),
          ),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(photoPath!), fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          context.t('tapToReplacePhoto'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.text),
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  context.t('attachPhoto'),
                  style: TextStyle(fontSize: 11, color: palette.muted, fontFamily: 'monospace'),
                ),
        ),
      ),
    );
  }
}
