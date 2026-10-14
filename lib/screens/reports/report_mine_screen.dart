import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/condition_report.dart';
import '../../models/report_filters.dart';
import '../../providers/reports_provider.dart';
import '../../services/read_aloud_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_selector.dart';
import '../../widgets/condition_tile.dart';
import '../../widgets/read_aloud_button.dart';

/// "My Reports": ONLY the signed-in user's own condition reports, live from
/// Firestore via [ReportsProvider] → `ConditionReportService` →
/// `FirebaseConditionReportRepository` (`where userId == <auth uid>`).
///
/// Reached from the passenger Report tab, the volunteer Reports tab, the
/// report confirmation screen, and the volunteer dashboard's statistics
/// cards (which can open it pre-filtered via [initialStatus]).
///
/// Ordering: verified/accepted first, then under review, then rejected;
/// newest first within each group. Status and subject filters combine and
/// run on the already-loaded list, so changing them costs no Firestore
/// reads.
class ReportMineScreen extends StatefulWidget {
  const ReportMineScreen({super.key, this.initialStatus = StatusFilter.all});

  final StatusFilter initialStatus;

  @override
  State<ReportMineScreen> createState() => _ReportMineScreenState();
}

class _ReportMineScreenState extends State<ReportMineScreen> {
  late StatusFilter _status = widget.initialStatus;
  SubjectFilter _subject = SubjectFilter.all;

  void _clearFilters() => setState(() {
    _status = StatusFilter.all;
    _subject = SubjectFilter.all;
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final role = context.watch<AppState>().role;
    final provider = context.watch<ReportsProvider>();
    final all = provider.reports;

    final query = ReportQuery(status: _status, subject: _subject);
    final visible = query.apply(all);

    // Status chip counts are within the chosen subject.
    final inSubject = all.where(_subject.matches).toList();
    int statusCount(StatusFilter f) => inSubject.where(f.matches).length;

    // Buses / Stations always; rest areas / other only if the user has
    // such reports (they are always included under "All").
    final subjects = [
      SubjectFilter.all,
      SubjectFilter.bus,
      SubjectFilter.station,
      for (final extra in [SubjectFilter.restArea, SubjectFilter.other])
        if (extra == _subject || all.any(extra.matches)) extra,
    ];

    final Widget content;
    if (provider.isLoading && all.isEmpty) {
      content = Semantics(
        label: context.t('loading'),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (provider.error != null && all.isEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.danger),
            ),
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            label: context.t('tryAgain'),
            onPressed: provider.loadReports,
          ),
        ],
      );
    } else if (all.isEmpty) {
      content = _EmptyState(
        icon: Icons.assignment_outlined,
        title: context.t('noReportsYet'),
        message: context.t('noReportsNote'),
      );
    } else if (visible.isEmpty) {
      content = _EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: context.t('noMatchingReports'),
        message: context.t(
          _status == StatusFilter.verified && _subject == SubjectFilter.all
              ? 'noVerifiedReportsNote'
              : 'noMatchingReportsNote',
        ),
        actionLabel: context.t('clearFilters'),
        onAction: _clearFilters,
      );
    } else {
      content = _ReportList(
        reports: visible,
        grouped: _status == StatusFilter.all,
      );
    }

    return AppScaffold(
      routeName: Routes.reportMine,
      title: context.t('myReportsTitle'),
      actions: [ReadAloudButton(summary: (t) => _summary(t, all, visible))],
      onBack: () =>
          Navigator.of(context).pushReplacementNamed(Routes.homeFor(role)),
      scrollableBody: false,
      body: RefreshIndicator(
        onRefresh: provider.loadReports,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (all.isNotEmpty) ...[
              _FilterGroup(
                label: context.t('statusFilterLabel'),
                children: [
                  for (final f in StatusFilter.values)
                    SelectableChip(
                      label: '${context.t(f.labelKey)} (${statusCount(f)})',
                      selected: _status == f,
                      onTap: () => setState(() => _status = f),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _FilterGroup(
                label: context.t('subjectFilterLabel'),
                children: [
                  for (final f in subjects)
                    SelectableChip(
                      label: context.t(f.labelKey),
                      selected: _subject == f,
                      onTap: () => setState(() => _subject = f),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(
                  context.tf('showingReports', {
                    'shown': visible.length,
                    'total': all.length,
                  }),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            content,
            if (visible.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                context.t('reportsReviewNote'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _summary(
    StringLookup t,
    List<ConditionReport> all,
    List<ConditionReport> visible,
  ) {
    int count(bool Function(ReportStatus) test) =>
        all.where((r) => test(r.status)).length;
    return [
      fillTemplate(t('summaryMyReports'), {'n': visible.length}),
      if (all.isNotEmpty)
        fillTemplate(t('summaryStatusCounts'), {
          'pending': count((s) => s.isPending),
          'accepted': count((s) => s.isAccepted),
          'rejected': count((s) => s.isRejected),
        }),
      if (_status != StatusFilter.all || _subject != SubjectFilter.all)
        fillTemplate(t('summaryFiltered'), {
          'status': t(_status.labelKey),
          'subject': t(_subject.labelKey),
        }),
    ].join(' ');
  }
}

/// The report cards, either flat or under "Verified by admin / Under review
/// / Rejected" headings (each group already newest first).
class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports, required this.grouped});

  final List<ConditionReport> reports;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    if (!grouped) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final report in reports) ...[
            ConditionTile.fromReport(report),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    const groups = [
      (StatusFilter.verified, 'groupVerified', Icons.verified_outlined),
      (StatusFilter.underReview, 'groupUnderReview', Icons.schedule_outlined),
      (StatusFilter.rejected, 'groupRejected', Icons.block_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (filter, labelKey, icon) in groups)
          if (reports.any(filter.matches)) ...[
            _GroupHeading(
              icon: icon,
              label: context.t(labelKey),
              count: reports.where(filter.matches).length,
            ),
            const SizedBox(height: 8),
            for (final report in reports.where(filter.matches)) ...[
              ConditionTile.fromReport(report),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      header: true,
      label: context.tf('groupCount', {'label': label, 'n': count}),
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.text),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: palette.muted,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
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
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.muted, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            SecondaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
