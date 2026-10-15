import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/accessibility_shortcut_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/condition_tile.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/read_aloud_button.dart';

/// Passenger Home: brand header, greeting banner, the main Plan Journey
/// card, quick actions (Share Journey, Report a Condition) and recent
/// activity. Every action keeps its original route.
///
/// Only the signed-in user's real data is shown: their profile name (once
/// loaded) and their latest condition reports — no sample content.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _greetingKey(DateTime now) => now.hour < 12
      ? 'goodMorning'
      : now.hour < 17
      ? 'goodAfternoon'
      : 'goodEvening';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final profile = context.watch<AuthState>().profile;
    final name = profile?.name.trim() ?? '';
    void go(String route) => Navigator.of(context).pushReplacementNamed(route);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: AppScaffold(
        routeName: Routes.home,
        scrollableBody: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: BrandMark(badgeSize: 40, fontSize: 19),
                    ),
                  ),
                  ReadAloudButton(
                    summary: (t) => [
                      t('summaryPassengerHome'),
                      fillTemplate(t('summaryActions'), {
                        'actions':
                            '${t('planJourney')}, ${t('shareJourney')} '
                            '${t('summaryAnd')} ${t('reportCondition')}',
                      }),
                    ].join(' '),
                  ),
                  const AccessibilityShortcutButton(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                // Bottom space keeps the last card clear of the SOS button.
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GreetingBanner(
                      greeting: context.t(_greetingKey(DateTime.now())),
                      name: name.isEmpty ? null : name,
                      prompt: context.t('homePrompt'),
                    ),
                    const SizedBox(height: 16),
                    _FeatureCard(
                      icon: Icons.place_rounded,
                      title: context.t('planJourney'),
                      description: context.t('planJourneyDesc'),
                      onTap: () => go(Routes.planSearch),
                    ),
                    const SizedBox(height: 22),
                    _SectionTitle(
                      icon: Icons.bolt_rounded,
                      text: context.t('quickActions'),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _QuickTile(
                              icon: Icons.share_location_rounded,
                              tint: palette.success,
                              tintSoft: palette.successSoft,
                              title: context.t('shareJourney'),
                              description: context.t('shareJourneyDesc'),
                              onTap: () => go(Routes.shareSetup),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickTile(
                              icon: Icons.add_location_alt_rounded,
                              tint: palette.cta,
                              tintSoft: palette.ctaSoft,
                              title: context.t('reportCondition'),
                              description: context.t('reportConditionDescHome'),
                              onTap: () => go(Routes.reportForm),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    HomeFeatureCard(
                      title: context.t('requestAssistanceTitle'),
                      description: context.t('requestAssistanceHomeDesc'),
                      icon: Icons.support_agent_rounded,
                      imageAsset: 'assets/artwork/care_support_icon.png',
                      onTap: () => go(Routes.requestAssistance),
                    ),
                    const SizedBox(height: 12),
                    HomeExploreBanner(
                      title: context.t('exploreColomboTitle'),
                      description: context.t('exploreColomboDesc'),
                      onTap: () => go(Routes.planSearch),
                    ),
                    const SizedBox(height: 22),
                    _SectionTitle(
                      icon: Icons.history_rounded,
                      text: context.t('recentActivity'),
                      action: TextButton(
                        onPressed: () => go(Routes.reportMine),
                        child: Text(context.t('viewAll')),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _RecentActivity(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastel banner: greeting, name and prompt over the Colombo skyline.
class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner({
    required this.greeting,
    required this.name,
    required this.prompt,
  });

  final String greeting;

  /// The user's profile name; null until it has loaded (nothing is shown
  /// in its place).
  final String? name;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: palette.cardOutline,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.accentSoft, palette.surface],
        ),
      ),
      child: Stack(
        children: [
          // Waterfront artwork on the right, faded into the card and behind
          // the text; it never sets the banner's height.
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            width: 170,
            child: ExcludeSemantics(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.transparent, Colors.black],
                  stops: [0, 0.6],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/artwork/colombo_skyline_waterfront.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            // Greeting + name read together as the screen heading.
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.muted,
                    ),
                  ),
                  if (name != null) ...[
                    const SizedBox(height: 2),
                    FractionallySizedBox(
                      widthFactor: 0.62,
                      child: Semantics(
                        header: true,
                        child: Text(
                          name!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: palette.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: palette.text,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The main, full-width feature card (Plan Journey).
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _TappableCard(
      label: '$title. $description',
      onTap: onTap,
      color: palette.surface,
      borderColor: palette.accent.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: palette.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: palette.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: palette.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Half-width quick action with a tinted icon.
class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.tint,
    required this.tintSoft,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color tintSoft;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _TappableCard(
      label: '$title. $description',
      onTap: onTap,
      color: tintSoft.withValues(alpha: 0.45),
      borderColor: tint.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tint, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.5,
                color: palette.muted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded, softly shadowed surface announced as one button.
class _TappableCard extends StatelessWidget {
  const _TappableCard({
    required this.label,
    required this.onTap,
    required this.color,
    required this.borderColor,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(22);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: palette.isHighContrast ? palette.cardBorder : borderColor,
              width: palette.isHighContrast ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        ExcludeSemantics(child: Icon(icon, size: 20, color: palette.accent)),
        const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

/// The user's three most recent condition reports (live from Firestore via
/// [ReportsProvider], newest first), with loading / error / empty states.
class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  static const _limit = 3;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final provider = context.watch<ReportsProvider>();
    final recent = provider.reports.take(_limit).toList();

    if (recent.isEmpty) {
      final String message;
      if (provider.isLoading) {
        return Semantics(
          label: context.t('loading'),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      } else if (provider.error != null) {
        // Short and non-technical here; My Reports shows the full reason.
        message = context.t('recentActivityUnavailable');
      } else {
        message = context.t('recentActivityEmpty');
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: palette.cardOutline,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                provider.error != null
                    ? Icons.cloud_off_outlined
                    : Icons.inbox_outlined,
                color: palette.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13.5,
                  color: palette.muted,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final report in recent) ...[
          ConditionTile.fromReport(report),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
