import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../services/admin_report_service.dart';

/// Asks the admin to confirm accepting a report, with an OPTIONAL note.
///
/// Returns null if cancelled; otherwise the trimmed note (possibly empty).
Future<String?> showAcceptReportDialog(
  BuildContext context, {
  String? initialNote,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ReviewNoteDialog(
      title: 'Accept this report?',
      message: 'The reporter will see it as Accepted in My Reports.',
      hint: 'Optional note for the reporter',
      confirmLabel: 'Accept',
      confirmColor: context.palette.success,
      noteRequired: false,
      initialNote: initialNote,
    ),
  );
}

/// Asks the admin for a MANDATORY rejection reason.
///
/// Returns null if cancelled; otherwise the trimmed, non-empty reason.
Future<String?> showRejectReportDialog(
  BuildContext context, {
  String? initialNote,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ReviewNoteDialog(
      title: 'Reject this report',
      message: 'Please tell the reporter why this report is being rejected.',
      hint: 'Reason for rejection',
      confirmLabel: 'Reject',
      confirmColor: context.palette.danger,
      noteRequired: true,
      initialNote: initialNote,
    ),
  );
}

/// Adds or edits the admin comment without changing the report status.
///
/// Returns null if cancelled; otherwise the trimmed, non-empty comment.
Future<String?> showEditCommentDialog(
  BuildContext context, {
  String? initialNote,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ReviewNoteDialog(
      title: (initialNote ?? '').isEmpty ? 'Add comment' : 'Edit comment',
      message: 'The reporter sees this comment with the report status.',
      hint: 'Admin comment',
      confirmLabel: 'Save',
      confirmColor: context.palette.cta,
      noteRequired: true,
      initialNote: initialNote,
    ),
  );
}

/// Asks the admin to confirm permanently deleting a report.
///
/// Returns true only if the admin confirmed.
Future<bool> showDeleteReportDialog(BuildContext context) async {
  final palette = context.palette;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete this report?'),
      content: Text(
        'The report and its photo will be permanently removed. '
        'This cannot be undone.',
        style: TextStyle(fontSize: 14, color: palette.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        _DialogConfirmButton(
          label: 'Delete',
          color: palette.danger,
          onPressed: () => Navigator.of(dialogContext).pop(true),
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
  final String? initialNote;

  const _ReviewNoteDialog({
    required this.title,
    required this.message,
    required this.hint,
    required this.confirmLabel,
    required this.confirmColor,
    required this.noteRequired,
    this.initialNote,
  });

  @override
  State<_ReviewNoteDialog> createState() => _ReviewNoteDialogState();
}

class _ReviewNoteDialogState extends State<_ReviewNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialNote);

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
    final palette = context.palette;
    return AlertDialog(
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
                style: TextStyle(fontSize: 14, color: palette.muted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                autofocus: widget.noteRequired,
                minLines: 3,
                maxLines: 5,
                maxLength: AdminReportService.maxCommentLength,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 14, color: palette.text),
                decoration: InputDecoration(hintText: widget.hint),
                validator: widget.noteRequired
                    ? (value) => (value == null || value.trim().isEmpty)
                          ? 'This can\'t be empty.'
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
          child: const Text('Cancel'),
        ),
        _DialogConfirmButton(
          label: widget.confirmLabel,
          color: widget.confirmColor,
          onPressed: _confirm,
        ),
      ],
    );
  }
}

class _DialogConfirmButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _DialogConfirmButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
