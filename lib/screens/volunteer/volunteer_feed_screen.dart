import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/public_condition_report.dart';
import '../../models/report_filters.dart';
import '../../providers/community_reports_provider.dart';
import '../../services/read_aloud_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_selector.dart';
import '../../widgets/community_report_card.dart';
import '../../widgets/read_aloud_button.dart';

/// Community Reports — verified reports other passengers and volunteers
/// chose to share, live from `public_condition_reports` via
/// [CommunityReportsProvider]. Kept separate from the user's own My
/// Reports (the Reports tab).
///
/// Only published copies are read: a report appears here once an admin
/// has accepted it AND its reporter opted in to sharing, and disappears
/// as soon as it is unpublished, rejected or deleted. Nothing here falls
/// back to sample data.
class VolunteerFeedScreen extends StatelessWidget {
  const VolunteerFeedScreen({super.key});

  static const _typeFilters = [
    (TypeFilter.all, 'allReportsFilter'),
    (TypeFilter.positive, 'positiveFilter'),
    (TypeFilter.issue, 'issuesFilter'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final provider = context.watch<CommunityReportsProvider>();
    final all = provider.allReports;
    final visible = provider.reports;

    // Buses / Stations always; rest areas / other when the feed has them.
    final subjects = [
      SubjectFilter.all,
      SubjectFilter.bus,
      SubjectFilter.station,
      for (final extra in [SubjectFilter.restArea, SubjectFilter.other])
        if (extra == provider.subject ||
            all.any((r) => extra.matchesSubject(r.subject)))
          extra,
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
            onPressed: provider.refresh,
          ),
        ],
      );
    } else if (all.isEmpty) {
      content = _EmptyState(
        icon: Icons.forum_outlined,
        title: context.t('communityEmptyTitle'),
        message: context.t('communityEmptyNote'),
      );
    } else if (visible.isEmpty) {
      content = _EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: context.t('noMatchingReports'),
        message: context.t('communityNoMatchNote'),
        actionLabel: context.t('clearFilters'),
        onAction: provider.clearFilters,
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final report in visible) ...[
            CommunityReportCard(
              report: report,
              onTap: () => Navigator.of(context)
                  .pushNamed(Routes.communityReportDetails, arguments: report),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return AppScaffold(
      routeName: Routes.volunteerFeed,
      title: context.t('communityReports'),
      actions: [
        ReadAloudButton(summary: (t) => _summary(t, provider, visible)),
      ],
      onBack: () =>
          Navigator.of(context).pushReplacementNamed(Routes.volunteerHome),
      scrollableBody: false,
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          // Bottom space keeps the last card clear of the SOS button.
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              context.t('communityIntro'),
              style: TextStyle(fontSize: 13, color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            _FilterGroup(
              label: context.t('subjectFilterLabel'),
              children: [
                for (final f in subjects)
                  SelectableChip(
                    label: context.t(f.labelKey),
                    selected: provider.subject == f,
                    onTap: () => provider.setSubject(f),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _FilterGroup(
              label: context.t('typeFilterLabel'),
              children: [
                for (final (f, key) in _typeFilters)
                  SelectableChip(
                    label: context.t(key),
                    selected: provider.type == f,
                    onTap: () => provider.setType(f),
                  ),
              ],
            ),
            if (all.isNotEmpty) ...[
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
            ],
            const SizedBox(height: 14),
            content,
            if (provider.hasMore && all.isNotEmpty) ...[
              const SizedBox(height: 4),
              SecondaryButton(
                label: context.t('showOlderReports'),
                onPressed: provider.isLoading ? null : provider.loadMore,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _typeLabelKey(TypeFilter type) =>
      _typeFilters.firstWhere((e) => e.$1 == type).$2;

  String _summary(
    StringLookup t,
    CommunityReportsProvider provider,
    List<PublicConditionReport> visible,
  ) {
    return [
      fillTemplate(t('summaryCommunity'), {'n': visible.length}),
      if (provider.isFiltered)
        fillTemplate(t('summaryCommunityFilters'), {
          'subject': t(provider.subject.labelKey),
          'type': t(_typeLabelKey(provider.type)),
        }),
      for (final report in visible.take(5))
        '${report.headline}. ${report.reportType.label}. '
            '${report.locationLabel}.',
    ].join(' ');
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
