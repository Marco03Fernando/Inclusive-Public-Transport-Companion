import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/condition_report.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../models/report_filter.dart';
import '../providers/admin_reports_provider.dart';
import '../../utils/admin_formatters.dart';
import '../widgets/admin_info_row.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/review_dialogs.dart';

/// Full detail of one report, with Accept / Reject for reports that are
/// still under review, and Delete for any report.
///
/// The screen re-reads the report from [AdminReportsProvider] on every
/// build, so if another admin reviews it while this screen is open, the
/// status (and the action buttons) update immediately.
class AdminReportDetailsScreen extends StatelessWidget {
  /// The report as it was when the admin tapped it. Only a fallback —
  /// the live copy from the provider is what gets displayed.
  final ConditionReport initialReport;

  const AdminReportDetailsScreen({super.key, required this.initialReport});

  Future<void> _accept(BuildContext context, ConditionReport report) async {
    final note = await showAcceptReportDialog(context);
    if (note == null || !context.mounted) return;

    final provider = context.read<AdminReportsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await provider.acceptReport(report.id, comment: note);

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report accepted.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not accept.')),
      );
    }
  }

  Future<void> _reject(BuildContext context, ConditionReport report) async {
    final reason = await showRejectReportDialog(context);
    if (reason == null || !context.mounted) return;

    final provider = context.read<AdminReportsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await provider.rejectReport(report.id, reason);

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report rejected.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not reject.')),
      );
    }
  }

  Future<void> _delete(BuildContext context, ConditionReport report) async {
    final confirmed = await showDeleteReportDialog(context);
    if (!confirmed || !context.mounted) return;

    final provider = context.read<AdminReportsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await provider.deleteReport(report.id);

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report deleted.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.actionError ?? 'Could not delete.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminReportsProvider>();
    final report = provider.reportById(initialReport.id) ?? initialReport;
    final isPending = report.status.isPending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          IconButton(
            tooltip: 'Delete report',
            icon: const Icon(Icons.delete_outline),
            onPressed:
                provider.isUpdating ? null : () => _delete(context, report),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PhotoView(url: report.photoUrl),
                  const SizedBox(height: AppSpacing.md),
                  AdminSectionCard(
                    title: 'Report information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          label: 'Submitted',
                          value: AdminFormat.dateTime(report.createdAt),
                        ),
                        if (report.updatedAt != null)
                          AdminInfoRow(
                            label: 'Last updated',
                            value: AdminFormat.dateTime(report.updatedAt!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
                  AdminSectionCard(
                    title: 'Description',
                    child: SelectableText(
                      report.description.trim().isEmpty
                          ? 'No description provided.'
                          : report.description,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AdminSectionCard(
                    title: 'Submitted by',
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
                      ],
                    ),
                  ),
                  if (!isPending &&
                      (report.adminComment ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    AdminSectionCard(
                      title: report.status.isRejected
                          ? 'Rejection reason'
                          : 'Admin comment',
                      child: SelectableText(
                        report.adminComment!,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isPending)
              _ActionBar(
                isBusy: provider.isUpdating,
                onAccept: () => _accept(context, report),
                onReject: () => _reject(context, report),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom bar with the two review actions.
class _ActionBar extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ActionBar({
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grey300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Neutral "saving..." indicator — shown for either action.
          if (isBusy) const LinearProgressIndicator(minHeight: 3),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('REJECT'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(
                        color: AppColors.danger,
                        width: 1.5,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('ACCEPT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The photo uploaded by the reporter (Firebase Storage download URL).
/// Tap to open full screen with pinch-to-zoom.
class _PhotoView extends StatelessWidget {
  final String? url;

  const _PhotoView({required this.url});

  @override
  Widget build(BuildContext context) {
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
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                final total = progress.expectedTotalBytes;
                return Container(
                  color: AppColors.grey100,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: total == null
                        ? null
                        : progress.cumulativeBytesLoaded / total,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const _PhotoPlaceholder(
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
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: AppColors.grey500),
          const SizedBox(height: AppSpacing.xs),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Photo',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
