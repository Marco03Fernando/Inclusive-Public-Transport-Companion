import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/public_condition_report.dart';
import '../../models/report_exception.dart';
import '../../repositories/community_report_repository.dart';
import '../../services/read_aloud_service.dart';
import '../../utils/admin_formatters.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/condition_tile.dart';
import '../../widgets/read_aloud_button.dart';
import '../../widgets/status_badge.dart';

/// "Report Details" for one Community Reports entry — read-only, built
/// only from the published copy (`public_condition_reports/{id}`), so
/// there is nothing private here to leak: no UID, contact details, exact
/// GPS position, admin comment or audit metadata.
///
/// It stays subscribed to that copy: if the report is unpublished,
/// rejected or deleted while open, the details are replaced by a "no
/// longer available" message instead of lingering on screen.
class CommunityReportDetailsScreen extends StatefulWidget {
  const CommunityReportDetailsScreen({super.key, required this.initialReport});

  /// The card that was tapped — shown until the live copy arrives.
  final PublicConditionReport initialReport;

  @override
  State<CommunityReportDetailsScreen> createState() =>
      _CommunityReportDetailsScreenState();
}

class _CommunityReportDetailsScreenState
    extends State<CommunityReportDetailsScreen> {
  late Stream<PublicConditionReport?> _report;

  @override
  void initState() {
    super.initState();
    _report = _watch();
  }

  Stream<PublicConditionReport?> _watch() => context
      .read<CommunityReportRepository>()
      .watchReport(widget.initialReport.id);

  void _retry() => setState(() => _report = _watch());

  Future<void> _openMap(PublicConditionReport report) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.t('mapOpenFailed');
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${report.latitude},${report.longitude}',
    });
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PublicConditionReport?>(
      stream: _report,
      initialData: widget.initialReport,
      builder: (context, snapshot) {
        final Widget body;
        PublicConditionReport? shown;
        if (snapshot.hasError) {
          final error = snapshot.error;
          body = _Message(
            icon: Icons.cloud_off_outlined,
            title: error is ReportException
                ? error.message
                : context.t('reportUnavailableTitle'),
            actionLabel: context.t('tryAgain'),
            onAction: _retry,
          );
        } else if (snapshot.data == null) {
          // Unpublished / rejected / deleted: show nothing of it any more.
          body = _Message(
            icon: Icons.visibility_off_outlined,
            title: context.t('reportUnavailableTitle'),
            message: context.t('reportUnavailableNote'),
            actionLabel: context.t('backToCommunity'),
            onAction: () => Navigator.of(context).maybePop(),
          );
        } else {
          shown = snapshot.data!;
          body = _Details(report: shown, onOpenMap: () => _openMap(shown!));
        }

        final report = shown;
        return AppScaffold(
          routeName: Routes.communityReportDetails,
          title: context.t('reportDetailsTitle'),
          onBack: () => Navigator.of(context).maybePop(),
          actions: [
            if (report != null)
              ReadAloudButton(summary: (t) => _summary(t, report)),
          ],
          body: Padding(
            // Keeps the last section clear of the SOS button.
            padding: const EdgeInsets.only(bottom: 76),
            child: body,
          ),
        );
      },
    );
  }

  static String _summary(StringLookup t, PublicConditionReport report) {
    return fillTemplate(t('summaryReportDetails'), {
      'headline': report.headline,
      'type': report.reportType.label,
      'name': report.contributorName ?? t('anonymousContributor'),
      'date': report.submittedLabel,
      'location': report.locationLabel,
      'description': report.description.trim(),
    });
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.report, required this.onOpenMap});

  final PublicConditionReport report;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final description = report.description.trim();
    final reference = report.vehicleOrStationNumber.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            report.headline,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.text,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ReportTypeLine(
          reportType: report.reportType,
          routeLabel: report.routeLabel,
        ),
        const SizedBox(height: 16),
        _Section(
          title: context.t('detailReportInfo'),
          children: [
            _InfoRow(
              label: context.t('detailReportType'),
              value: context.t(report.reportType.labelKey),
            ),
            _InfoRow(
              label: context.t('detailReportedBy'),
              value:
                  report.contributorName ?? context.t('anonymousContributor'),
            ),
            _InfoRow(
              label: context.t('detailSubmitted'),
              value: AdminFormat.dateTime(report.createdAt),
            ),
            if (report.routeLabel != null)
              _InfoRow(
                label: context.t('detailBusRoute'),
                value: report.routeLabel!,
              ),
            _InfoRow(
              label: context.t('detailSubject'),
              value: context.t(report.subject.labelKey),
            ),
            if (reference.isNotEmpty)
              _InfoRow(label: context.t('detailReference'), value: reference),
            _InfoRow(
              label: context.t('detailCondition'),
              value: context.t(report.conditionType.labelKey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: context.t('detailLocation'),
          children: [
            Text(
              report.locationLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            if (report.hasApproximatePosition) ...[
              const SizedBox(height: 4),
              Text(
                context.t('approxLocationNote'),
                style: TextStyle(fontSize: 12.5, color: palette.muted),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: context.t('viewOnMap'),
                onPressed: onOpenMap,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: context.t('detailDescription'),
          children: [
            Text(
              description.isEmpty
                  ? context.t('noDescriptionProvided')
                  : description,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: description.isEmpty ? palette.muted : palette.text,
              ),
            ),
          ],
        ),
        if (report.hasPhoto) ...[
          const SizedBox(height: 12),
          _Section(
            title: context.t('detailPhoto'),
            children: [_Photo(url: report.photoUrl!)],
          ),
        ],
        const SizedBox(height: 12),
        _Section(
          title: context.t('detailVerification'),
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.verified_outlined,
                    size: 20,
                    color: palette.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.t('communityVerifiedByAdmin'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  status: report.status,
                  label: context.t('communityVerified'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// A titled surface card grouping related details.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: palette.cardOutline,
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// "Label" over "value", read as one item ("Reported by, Kamala").
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      image: true,
      label: context.t('reportPhotoA11y'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(
                    color: palette.surface2,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
            errorBuilder: (context, _, _) => Container(
              color: palette.surface2,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Text(
                context.t('photoLoadFailed'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Semantics(
        liveRegion: true,
        child: Column(
          children: [
            ExcludeSemantics(child: Icon(icon, size: 40, color: palette.muted)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.muted,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SecondaryButton(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
