import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/buttons.dart';
import '../../widgets/language_toggle.dart';

/// The app's entry / "Get Started" screen (route [Routes.roleSelect]).
///
/// Behaviour is unchanged from the original role picker:
///  - Get Started → choose Passenger or Volunteer (bottom sheet) → the role
///    is set on [AppState] and sign-up opens ([Routes.signupBasic]),
///  - Log in → [Routes.login],
///  - Continue as Guest → anonymous volunteer → [Routes.volunteerHome],
///  - the language toggle switches English / Sinhala.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  bool _guestLoading = false;

  Future<void> _continueAsGuest(BuildContext context) async {
    setState(() => _guestLoading = true);
    final ok = await context.read<AuthState>().continueAsGuest();
    if (!context.mounted) return;
    setState(() => _guestLoading = false);
    if (ok) Navigator.of(context).pushReplacementNamed(Routes.volunteerHome);
  }

  void _choose(AppRole role) {
    context.read<AppState>().setRole(role);
    Navigator.of(context).pushReplacementNamed(Routes.signupBasic);
  }

  Future<void> _getStarted() async {
    final role = await showModalBottomSheet<AppRole>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _RolePickerSheet(),
    );
    if (role != null && mounted) _choose(role);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();

    return AppScaffold(
      routeName: Routes.roleSelect,
      scrollableBody: false,
      body: DecoratedBox(
        // Soft sky wash from the brand tint at the top into the page colour.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.accentSoft.withValues(alpha: 0.7), palette.bg],
            stops: const [0, 0.6],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // Lets the Spacer below push the actions to the bottom on tall
              // screens, while short / large-text screens simply scroll.
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: LanguageToggle(
                          locale: state.locale,
                          onChanged: state.setLocale,
                        ),
                      ),
                    ),
                    const _BrandHeader(),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Semantics(
                        header: true,
                        child: Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${context.t('landingHeadlineTop')}\n',
                              ),
                              TextSpan(
                                text: context.t('landingHeadlineAccent'),
                                style: TextStyle(color: palette.accent),
                              ),
                            ],
                          ),
                          style: GoogleFonts.manrope(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                            letterSpacing: -0.4,
                            color: palette.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        context.t('appTagline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: palette.muted,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const Expanded(child: _SceneWithBenefits()),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: PrimaryButton(
                        label: context.t('getStarted'),
                        onPressed: _getStarted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.t('haveAccount'),
                          style: TextStyle(fontSize: 14, color: palette.muted),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed(Routes.login),
                          child: Text(
                            context.t('logIn'),
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: TextButton(
                        onPressed: _guestLoading
                            ? null
                            : () => _continueAsGuest(context),
                        child: Text(
                          _guestLoading
                              ? context.t('loading')
                              : context.t('continueAsGuest'),
                          style: TextStyle(
                            color: palette.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred logo badge with the "Colombo Pal" wordmark beneath it.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'Colombo Pal',
      excludeSemantics: true,
      child: Column(
        children: [
          const BrandBadge(size: 92),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Colombo ',
                  style: TextStyle(color: palette.text),
                ),
                TextSpan(
                  text: 'Pal',
                  style: TextStyle(color: palette.accent),
                ),
              ],
            ),
            style: GoogleFonts.manrope(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width scene artwork, faded into the page at its top and bottom, with
/// the benefits card overlapping its lower edge.
class _SceneWithBenefits extends StatelessWidget {
  const _SceneWithBenefits();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Takes all the space between the text and the buttons: the artwork
    // fills it (anchored to the bottom) and the benefits card rests on it.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 340),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: ShaderMask(
                // Long, soft fades so the scene melts into the sky above and
                // the page colour below instead of ending in an edge.
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0, 0.4, 0.84, 1],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/artwork/inclusive_travel_people_and_bus.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(-0.25, 0.4),
                ),
              ),
            ),
          ),
          // Page-colour veil under the card so its text stays readable.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.bg.withValues(alpha: 0), palette.bg],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 22,
            right: 22,
            bottom: 0,
            child: _Benefits(),
          ),
        ],
      ),
    );
  }
}

/// Three short benefit points under the hero.
class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = [
      (
        Icons.accessible_forward_rounded,
        palette.accent,
        palette.accentSoft,
        'benefitRoutesTitle',
        'benefitRoutesDesc',
      ),
      (
        Icons.volunteer_activism_rounded,
        palette.success,
        palette.successSoft,
        'benefitHelpTitle',
        'benefitHelpDesc',
      ),
      (
        Icons.campaign_rounded,
        palette.cta,
        palette.ctaSoft,
        'benefitReportsTitle',
        'benefitReportsDesc',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: palette.cardOutline,
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: palette.border),
              Expanded(
                child: MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: items[i].$3,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(items[i].$1, color: items[i].$2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.t(items[i].$4),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.t(items[i].$5),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: palette.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "I am registering as a" — Passenger / Volunteer. Pops with the chosen
/// role; the screen then runs the same set-role + sign-up navigation as
/// the original role cards.
class _RolePickerSheet extends StatelessWidget {
  const _RolePickerSheet();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.t('registeringAs'),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _RoleOption(
              icon: Icons.person_rounded,
              tint: palette.accent,
              tintSoft: palette.accentSoft,
              title: context.t('rolePassenger'),
              description: context.t('passengerDesc'),
              onTap: () => Navigator.of(context).pop(AppRole.passenger),
            ),
            const SizedBox(height: 12),
            _RoleOption(
              icon: Icons.groups_rounded,
              tint: palette.success,
              tintSoft: palette.successSoft,
              title: context.t('roleVolunteer'),
              description: context.t('volunteerDesc'),
              onTap: () => Navigator.of(context).pop(AppRole.volunteer),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
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
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: tintSoft.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: palette.isHighContrast
                ? palette.cardBorder
                : tint.withValues(alpha: 0.35),
            width: palette.isHighContrast ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tint, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: tint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
