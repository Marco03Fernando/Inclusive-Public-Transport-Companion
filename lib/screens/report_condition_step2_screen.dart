import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/condition_report.dart';
import '../providers/reports_provider.dart';
import '../services/photo_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/section_label.dart';
import 'my_reports_screen.dart';

/// Screen 2: "Report Condition (2/2)"
///
/// Collects a short description and an optional photo (camera or
/// gallery), shows a live summary card, and submits the report via
/// `ReportsProvider` (backed by `ConditionReportService`). Matches
/// wireframe "11 Report Condition - Step 2 Photo".
class ReportConditionStep2Screen extends StatefulWidget {
  final ConditionReportDraft draft;

  const ReportConditionStep2Screen({super.key, required this.draft});

  @override
  State<ReportConditionStep2Screen> createState() =>
      _ReportConditionStep2ScreenState();
}

class _ReportConditionStep2ScreenState
    extends State<ReportConditionStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _photoService = PhotoService();

  String? _photoPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(PhotoSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final path = await _photoService.pickPhoto(source);
      if (path == null) return; // user cancelled picker
      setState(() => _photoPath = path);
    } on PhotoServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final draft = widget.draft;
    if (draft.subject == null || draft.conditionType == null) {
      // Defensive: Step 1 validation should already guarantee these.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing details from step 1 — please go back.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    draft.description = _descriptionController.text.trim();
    draft.photoPath = _photoPath;

    final report = ConditionReport.fromDraft(draft);
    final provider = context.read<ReportsProvider>();
    final success = await provider.submitReport(report);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not submit your report.')),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyReportsScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Report Condition (2/2)'),
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
                const SectionLabel('Short description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Describe what you saw...'),
                  validator: ReportValidators.description,
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionLabel('Add a photo (optional)'),
                _PhotoPicker(photoPath: _photoPath, onTap: _choosePhotoSource),
                const SizedBox(height: AppSpacing.lg),
                const SectionLabel('Summary'),
                _SummaryCard(draft: draft, description: _descriptionController.text),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('SUBMIT REPORT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onTap;

  const _PhotoPicker({required this.photoPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null;

    return Semantics(
      button: true,
      label: hasPhoto ? 'Photo added, tap to replace' : 'Tap to add photo',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          width: double.infinity,
          height: 160,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.black, width: 1.5),
          ),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(photoPath!), fit: BoxFit.cover),
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'TAP TO REPLACE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 28, color: AppColors.grey600),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'TAP TO ADD PHOTO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ConditionReportDraft draft;
  final String description;

  const _SummaryCard({required this.draft, required this.description});

  @override
  Widget build(BuildContext context) {
    final title = draft.summaryTitle.trim();
    final conditionLine = draft.conditionType?.sentenceCase;
    final locationLine =
        draft.location.trim().isEmpty ? null : 'Location: ${draft.location.trim()}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? '—' : title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (conditionLine != null) ...[
            const SizedBox(height: 4),
            Text(conditionLine, style: const TextStyle(fontSize: 14)),
          ],
          if (locationLine != null) ...[
            const SizedBox(height: 4),
            Text(
              locationLine,
              style: const TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
          ],
        ],
      ),
    );
  }
}
