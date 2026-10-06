import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Asks the admin to confirm accepting a report, with an OPTIONAL note.
///
/// Returns null if cancelled; otherwise the trimmed note (possibly empty).
Future<String?> showAcceptReportDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _ReviewNoteDialog(
      title: 'Accept this report?',
      message: 'The reporter will see it as Accepted.',
      hint: 'Optional note',
      confirmLabel: 'ACCEPT',
      confirmColor: AppColors.success,
      noteRequired: false,
    ),
  );
}

/// Asks the admin for a MANDATORY rejection reason.
///
/// Returns null if cancelled; otherwise the trimmed, non-empty reason.
Future<String?> showRejectReportDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _ReviewNoteDialog(
      title: 'Reject this report',
      message: 'Please tell the reporter why this report is being rejected.',
      hint: 'Reason for rejection',
      confirmLabel: 'REJECT',
      confirmColor: AppColors.danger,
      noteRequired: true,
    ),
  );
}

/// Asks the admin to confirm permanently deleting a report.
///
/// Returns true only if the admin confirmed.
Future<bool> showDeleteReportDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: const Text('Delete this report?'),
      content: const Text(
        'The report and its photo will be permanently removed. '
        'This cannot be undone.',
        style: TextStyle(fontSize: 14, color: AppColors.grey600),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('CANCEL'),
        ),
        // See _ReviewNoteDialog: override the theme's infinite min width.
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 48),
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
          ),
          child: const Text('DELETE'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _ReviewNoteDialog extends StatefulWidget {
  final String title;
  final String message;
  final String hint;
  final String confirmLabel;
  final Color confirmColor;
  final bool noteRequired;

  const _ReviewNoteDialog({
    required this.title,
    required this.message,
    required this.hint,
    required this.confirmLabel,
    required this.confirmColor,
    required this.noteRequired,
  });

  @override
  State<_ReviewNoteDialog> createState() => _ReviewNoteDialogState();
}

class _ReviewNoteDialogState extends State<_ReviewNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _controller,
                autofocus: widget.noteRequired,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: widget.hint),
                validator: widget.noteRequired
                    ? (value) => (value == null || value.trim().isEmpty)
                        ? 'Please enter a reason.'
                        : null
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        // The app theme gives ElevatedButton an infinite minimum width;
        // inside dialog actions that would fail layout, so override it.
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 48),
            backgroundColor: widget.confirmColor,
            foregroundColor: AppColors.white,
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
