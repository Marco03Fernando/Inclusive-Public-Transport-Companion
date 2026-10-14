import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/condition_report.dart';
import '../../utils/admin_formatters.dart';
import '../../widgets/buttons.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/status_badge.dart';
import '../models/report_filter.dart';
import '../providers/admin_reports_provider.dart';
import '../widgets/admin_info_row.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/review_dialogs.dart';

/// Full detail of one `condition_reports/{reportId}` document, with:
///  - Accept / Reject while it is under review,
///  - "Change to accepted / rejected" once it has been reviewed,
///  - Add / edit admin comment at any time,
///  - Delete.
///
/// Every action writes only `status`, `adminComment` and `updatedAt` on
/// the SAME document, so the reporter's live "My Reports" list updates by
/// itself. The screen re-reads the report from [AdminReportsProvider] on
/// every build, so changes made elsewhere show up immediately too.
class AdminReportDetailsScreen extends StatelessWidget {
  /// The report as it was when the admin tapped it. Only a fallback —
  /// the live copy from the provider is what gets displayed.
  final ConditionReport initialReport;

  const AdminReportDetailsScreen({super.key, required this.initialReport});

  Future<void> _accept(BuildContext context, ConditionReport report) async {
    final note = await showAcceptReportDialog(context);
    if (note == null || !context.mounted) return;
    await _runAction(
      context,
      (provider) => provider.acceptReport(report, comment: note),
      success: 'Report accepted.',
    );
  }

  Future<void> _reject(BuildContext context, ConditionReport report) async {
    final reason = await showRejectReportDialog(context);
    if (reason == null || !context.mounted) return;
    await _runAction(
      context,
      (provider) => provider.rejectReport(report, reason),
      success: 'Report rejected.',
    );
  }

  Future<void> _editComment(
    BuildContext context,
    ConditionReport report,
  ) async {
    final comment = await showEditCommentDialog(
      context,
      initialNote: report.adminComment,
    );
    if (comment == null || !context.mounted) return;
    await _runAction(
      context,
      (provider) => provider.updateComment(report.id, comment),
      success: 'Comment saved.',
    );
  }

  Future<void> _delete(BuildContext context, ConditionReport report) async {
    final confirmed = await showDeleteReportDialog(context);
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context);
    final ok = await _runAction(
      context,
      (provider) => provider.deleteReport(report.id),
      success: 'Report deleted.',
    );
    if (ok) navigator.pop();
  }

  /// Runs an update and reports the outcome (or the specific failure —
  /// permission / network / changed-by-someone-else) in a SnackBar.
  Future<bool> _runAction(
    BuildContext context,
    Future<bool> Function(AdminReportsProvider provider) action, {
    required String success,
  }) async {
    final provider = context.read<AdminReportsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action(provider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? success : (provider.actionError ?? 'Could not save changes.'),
        ),
      ),
    );
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final provider = context.watch<AdminReportsProvider>();
    final live = provider.reportById(initialReport.id);
    // Gone from the live list (deleted elsewhere) once data has loaded.
    final isDeleted = live == null && !provider.isLoading;
    final report = live ?? initialReport;
    final comment = (report.adminComment ?? '').trim();

    return Scaffold(
      appBar: const ScreenHeader(title: 'Report details'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  if (isDeleted) ...[
                    _Banner(
                      text: 'This report no longer exists.',
                      color: palette.danger,
                      background: palette.dangerSoft,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PhotoView(url: report.photoUrl),
                  const SizedBox(height: 14),
                  AdminSectionCard(
                    title: 'Report information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminInfoRow(
                          label: 'Report type',
                          value: report.reportType.label,
                        ),
                        AdminInfoRow(
                          label: 'Bus route',
                          value: report.routeLabel,
                        ),
                        AdminInfoRow(
                          label: 'Route ID (normalized)',
                          value: AdminFormat.routeId(report),
                        ),
                        AdminInfoRow(
                          label: 'Subject',
                          value: AdminFormat.subject(report.subject),
                        ),
                        AdminInfoRow(
                          label: 'Vehicle / station number',
                          value: AdminFormat.vehicleNumber(report),
                        ),
                        AdminInfoRow(
                          label: 'Condition type',
                          value: report.conditionType.sentenceCase,
                        ),
                        AdminInfoRow(
                          label: 'Status',
                          value: _statusText(report.status),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminSectionCard(
                    title: 'Description',
                    child: SelectableText(
                      report.description.trim().isEmpty
                          ? 'No description provided.'
                          : report.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: palette.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminSectionCard(
                    title: 'Location',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminInfoRow(
                          label: 'Location name',
                          value: AdminFormat.locationName(report),
                        ),
                        AdminInfoRow(
                          label: 'Coordinates (lat, lng)',
                          value: AdminFormat.coordinates(report.location),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminSectionCard(
                    title: 'Submission',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminInfoRow(
                          label: 'User ID',
                          value: report.userId.isEmpty
                              ? 'Unknown'
                              : report.userId,
                        ),
                        AdminInfoRow(label: 'Report ID', value: report.id),
                        AdminInfoRow(
                          label: 'Submitted',
                          value: AdminFormat.dateTime(report.createdAt),
                        ),
                        AdminInfoRow(
                          label: 'Last updated',
                          value: report.updatedAt == null
                              ? 'Not updated yet'
                              : AdminFormat.dateTime(report.updatedAt!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminSectionCard(
                    title: report.status.isRejected
                        ? 'Rejection reason'
                        : 'Admin comment',
                    trailing: TextButton.icon(
                      onPressed: provider.isUpdating || isDeleted
                          ? null
                          : () => _editComment(context, report),
                      icon: Icon(
                        comment.isEmpty ? Icons.add : Icons.edit_outlined,
                        size: 16,
                      ),
                      label: Text(comment.isEmpty ? 'Add' : 'Edit'),
                    ),
                    child: Text(
                      comment.isEmpty ? 'No comment yet.' : comment,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: comment.isEmpty ? palette.muted : palette.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextDangerButton(
                    label: 'Delete report',
                    onPressed: provider.isUpdating || isDeleted
                        ? null
                        : () => _delete(context, report),
                  ),
                ],
              ),
            ),
            if (!isDeleted)
              _ActionBar(
                status: report.status,
                isBusy: provider.isUpdating,
                onAccept: () => _accept(context, report),
                onReject: () => _reject(context, report),
              ),
          ],
        ),
      ),
    );
  }

  static String _statusText(ReportStatus status) {
    if (status.isPending) return 'Under review';
    if (status.isRejected) return 'Rejected';
    return 'Accepted';
  }
}

/// Bottom bar with the review actions. Under review → Reject / Accept;
/// already reviewed → a single "change decision" button.
class _ActionBar extends StatelessWidget {
  final ReportStatus status;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ActionBar({
    required this.status,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final Widget actions;
    if (status.isPending) {
      actions = Row(
        children: [
          Expanded(
            child: DangerButton(
              label: 'Reject',
              onPressed: isBusy ? null : onReject,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Accept',
              onPressed: isBusy ? null : onAccept,
            ),
          ),
        ],
      );
    } else if (status.isRejected) {
      actions = SecondaryButton(
        label: 'Change to accepted',
        onPressed: isBusy ? null : onAccept,
      );
    } else {
      actions = SecondaryButton(
        label: 'Change to rejected',
        onPressed: isBusy ? null : onReject,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Neutral "saving..." indicator — shown for any action.
          if (isBusy) const LinearProgressIndicator(minHeight: 3),
          Padding(padding: const EdgeInsets.all(16), child: actions),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _Banner({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// The photo uploaded by the reporter (its stored `photoUrl`, a Firebase
/// Storage download URL). Tap to open full screen with pinch-to-zoom.
class _PhotoView extends StatelessWidget {
  final String? url;

  const _PhotoView({required this.url});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final photoUrl = url;

    if (photoUrl == null || photoUrl.isEmpty) {
      return const _PhotoPlaceholder(
        icon: Icons.image_not_supported_outlined,
        text: 'No photo attached',
      );
    }

    return Semantics(
      button: true,
      image: true,
      label: 'Report photo. Tap to enlarge.',
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _FullScreenPhoto(url: photoUrl),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                final total = progress.expectedTotalBytes;
                return Container(
                  color: palette.surface2,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: total == null
                        ? null
                        : progress.cumulativeBytesLoaded / total,
                  ),
                );
              },
              errorBuilder: (_, _, _) => const _PhotoPlaceholder(
                icon: Icons.broken_image_outlined,
                text: 'Could not load photo',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PhotoPlaceholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: palette.muted),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  final String url;

  const _FullScreenPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photo'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'Could not load photo',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
