import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_filters.dart';
import '../../providers/reports_provider.dart';
import '../../services/read_aloud_service.dart';
import '../../widgets/accessibility_shortcut_button.dart';
import '../../widgets/action_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/read_aloud_button.dart';
import '../../widgets/stat_card.dart';

/// Volunteer Dashboard: welcome header (with Read Aloud and Accessibility
/// shortcuts), the volunteer's own report statistics, quick actions, and
/// the shared bottom nav + SOS from [AppScaffold].
///
/// Statistics come from [ReportsProvider] — the signed-in volunteer's live
/// `condition_reports`, the SAME list My Reports shows — so "Verified by
/// admin" counts accepted (and legacy "verified") reports, using the shared
/// [StatusFilter.verified] rule. Tapping a statistic opens My Reports (the
/// verified one pre-filtered to Verified).
///
/// The header is fixed and drawn behind the status bar (see
/// [GreetingHeader]); only the content below it scrolls.
class VolunteerHomeScreen extends StatelessWidget {
  const VolunteerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final profile = context.watch<AuthState>().profile;
    final hasRealName = profile?.name.isNotEmpty ?? false;
    final displayName = hasRealName ? profile!.name : 'Ruwan Jayasuriya';
    final initials = hasRealName ? profile!.initials : 'RJ';

    final stats = _VolunteerStats.from(context.watch<ReportsProvider>());

    void open(String route, {Object? arguments}) =>
        Navigator.of(context).pushReplacementNamed(route, arguments: arguments);

    return AppScaffold(
      routeName: Routes.volunteerHome,
      scrollableBody: false,
      safeAreaTop: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GreetingHeader(
            greeting: context.t('welcomeBack'),
            name: displayName,
            roleLabel: context.t('roleVolunteer'),
            initials: initials,
            actions: [
              ReadAloudButton(
                color: palette.onHero,
                summary: (t) => stats.summary(t),
              ),
              AccessibilityShortcutButton(color: palette.onHero),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                // Bottom space keeps the last card clear of the SOS button.
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile == null) const DemoDataBadge(),
                    _SectionHeading(context.t('yourActivity')),
                    const SizedBox(height: 10),
                    _StatsRow(
                      stats: stats,
                      onOpenAll: () => open(Routes.reportMine),
                      onOpenVerified: () => open(
                        Routes.reportMine,
                        arguments: StatusFilter.verified,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeading(context.t('quickActions')),
                    const SizedBox(height: 10),
                    ActionCard(
                      icon: Icons.add_location_alt_outlined,
                      title: context.t('reportCondition'),
                      description: context.t('volunteerReportDesc'),
                      onTap: () => open(Routes.reportForm),
                    ),
                    const SizedBox(height: 12),
                    ActionCard(
                      icon: Icons.forum_outlined,
                      title: context.t('communityReports'),
                      description: context.t('communityReportsDesc'),
                      onTap: () => open(Routes.volunteerFeed),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The volunteer's report counts, or null values while loading / when the
/// list couldn't be loaded (never placeholder numbers).
class _VolunteerStats {
  const _VolunteerStats({this.submitted, this.verified, this.failed = false});

  factory _VolunteerStats.from(ReportsProvider provider) {
    final reports = provider.reports;
    if (reports.isEmpty) {
      if (provider.isLoading) return const _VolunteerStats();
      if (provider.error != null) return const _VolunteerStats(failed: true);
    }
    return _VolunteerStats(
      submitted: reports.length,
      verified: reports.where(StatusFilter.verified.matches).length,
    );
  }

  final int? submitted;
  final int? verified;
  final bool failed;

  bool get isReady => submitted != null && verified != null;

  /// Read Aloud summary built from the real, current counts.
  String summary(StringLookup t) {
    final parts = <String>[t('summaryVolunteerHome')];
    if (isReady) {
      parts
        ..add('${fillTemplate(t('statSubmittedA11y'), {'n': submitted!})}.')
        ..add('${fillTemplate(t('statVerifiedA11y'), {'n': verified!})}.');
    } else if (!failed) {
      parts.add(t('summaryStatsLoading'));
    }
    parts.add(
      fillTemplate(t('summaryActions'), {
        'actions':
            '${t('reportCondition')} ${t('summaryAnd')} '
            '${t('communityReports')}',
      }),
    );
    return parts.join(' ');
  }
}

/// Two stat cards side by side; stacked when large text would cramp them.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.stats,
    required this.onOpenAll,
    required this.onOpenVerified,
  });

  final _VolunteerStats stats;
  final VoidCallback onOpenAll;
  final VoidCallback onOpenVerified;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    String value(int? n) => n?.toString() ?? '–';
    String a11y(String key, int? n) {
      if (n != null) return context.tf(key, {'n': n});
      return context.t(stats.failed ? 'statsUnavailable' : 'statsLoading');
    }

    final submitted = StatCard(
      icon: Icons.assignment_outlined,
      value: value(stats.submitted),
      label: context.t('reportsSubmitted'),
      semanticsLabel: a11y('statSubmittedA11y', stats.submitted),
      semanticsHint: context.t('statOpensMyReports'),
      onTap: onOpenAll,
    );
    final verified = StatCard(
      icon: Icons.verified_outlined,
      value: value(stats.verified),
      label: context.t('verifiedByAdmin'),
      valueColor: palette.success,
      semanticsLabel: a11y('statVerifiedA11y', stats.verified),
      semanticsHint: context.t('statOpensVerified'),
      onTap: onOpenVerified,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final stack = textScale >= 1.4 || constraints.maxWidth < 320;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [submitted, const SizedBox(height: 12), verified],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: submitted),
              const SizedBox(width: 12),
              Expanded(child: verified),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: palette.text,
        ),
      ),
    );
  }
}
