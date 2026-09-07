import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/condition_report.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/choice_tile_button.dart';
import '../widgets/section_label.dart';
import 'report_condition_step2_screen.dart';

/// Screen 1: "Report Condition (1/2)"
///
/// Collects: subject (Bus/Station/Rest area/Other), vehicle or station
/// number, location (via GPS), and condition type. Matches wireframe
/// "10 Report Condition - Step 1".
class ReportConditionStep1Screen extends StatefulWidget {
  const ReportConditionStep1Screen({super.key});

  @override
  State<ReportConditionStep1Screen> createState() =>
      _ReportConditionStep1ScreenState();
}

class _ReportConditionStep1ScreenState
    extends State<ReportConditionStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _draft = ConditionReportDraft();
  final _vehicleController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationService = LocationService();

  String? _subjectError;
  String? _conditionError;
  String? _locationError;
  bool _isLocating = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Checks GPS and asks the user for location permission.
  Future<bool> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      setState(() {
        _locationError =
            'Location services are turned off. Please turn on GPS and try again.';
      });

      return false;
    }

    var permission = await Geolocator.checkPermission();

    // This triggers the Android location permission popup.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return false;

      setState(() {
        _locationError =
            'Location permission is required to use your current location.';
      });

      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;

      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location permission required'),
          content: const Text(
            'Location permission has been permanently denied. '
            'Please enable location permission from the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OPEN SETTINGS'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await Geolocator.openAppSettings();
      }

      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final permissionGranted = await _checkLocationPermission();

      if (!permissionGranted) return;

      final location = await _locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        _draft.reportLocation = location;
        _locationController.text = location.label;
        _draft.location = location.label;
        _locationError = null;
      });
    } on LocationServiceException catch (e) {
      if (!mounted) return;

      setState(() => _locationError = e.message);
    } catch (_) {
      if (!mounted) return;

      setState(
        () => _locationError =
            'Could not get your location. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  bool _validateChoices() {
    setState(() {
      _subjectError = ReportValidators.subject(_draft.subject);
      _conditionError = ReportValidators.conditionType(_draft.conditionType);
    });
    return _subjectError == null && _conditionError == null;
  }

  void _goNext() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final choicesValid = _validateChoices();
    if (!formValid || !choicesValid) return;

    _draft.vehicleOrStationNumber = _vehicleController.text.trim();
    _draft.location = _locationController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportConditionStep2Screen(draft: _draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Report Condition (1/2)'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('What are you reporting?'),
                _SubjectGrid(
                  selected: _draft.subject,
                  onSelect: (s) => setState(() {
                    _draft.subject = s;
                    _subjectError = null;
                  }),
                ),
                if (_subjectError != null) _FieldError(_subjectError!),
                const SizedBox(height: AppSpacing.lg),
                const SectionLabel('Vehicle / Station number'),
                TextFormField(
                  controller: _vehicleController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'e.g. NB-1234'),
                  validator: (v) =>
                      ReportValidators.vehicleOrStationNumber(v, _draft.subject),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionLabel('Location'),
                TextFormField(
                  controller: _locationController,
                  readOnly: true,
                  onTap: _isLocating ? null : _useCurrentLocation,
                  validator: ReportValidators.location,
                  decoration: InputDecoration(
                    hintText: 'Use current location',
                    suffixIcon: _isLocating
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Use current location',
                            icon: const Icon(Icons.my_location, size: 20),
                            onPressed: _useCurrentLocation,
                          ),
                  ),
                ),
                if (_locationError != null) _FieldError(_locationError!),
                const SizedBox(height: AppSpacing.lg),
                const SectionLabel('Condition type'),
                _ConditionTypeGrid(
                  selected: _draft.conditionType,
                  onSelect: (c) => setState(() {
                    _draft.conditionType = c;
                    _conditionError = null;
                  }),
                ),
                if (_conditionError != null) _FieldError(_conditionError!),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _goNext,
                  child: const Text('NEXT: ADD DETAILS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  final String message;

  const _FieldError(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  final ReportSubject? selected;
  final ValueChanged<ReportSubject> onSelect;

  const _SubjectGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _TwoByTwoGrid(
      children: ReportSubject.values
          .map(
            (s) => ChoiceTileButton(
              label: s.label,
              selected: selected == s,
              onTap: () => onSelect(s),
            ),
          )
          .toList(),
    );
  }
}

class _ConditionTypeGrid extends StatelessWidget {
  final ConditionType? selected;
  final ValueChanged<ConditionType> onSelect;

  const _ConditionTypeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _TwoByTwoGrid(
      children: ConditionType.values
          .map(
            (c) => ChoiceTileButton(
              label: c.label,
              selected: selected == c,
              onTap: () => onSelect(c),
            ),
          )
          .toList(),
    );
  }
}

/// Lays out exactly 4 children in a 2x2 grid with consistent gaps,
/// matching the wireframe's paired button rows.
class _TwoByTwoGrid extends StatelessWidget {
  final List<Widget> children;

  const _TwoByTwoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: children[1]),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: children[2]),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: children[3]),
          ],
        ),
      ],
    );
  }
}