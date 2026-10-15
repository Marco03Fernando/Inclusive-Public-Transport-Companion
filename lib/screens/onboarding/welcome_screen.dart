import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../services/onboarding_prefs.dart';
import '../../widgets/artwork_image.dart';
import '../../widgets/language_toggle.dart';

/// First-run intro: three swipeable pages, then on to role select (the
/// existing sign-up entry) or log in. Shown once by `AuthGate` to someone
/// with no saved session; it only introduces the app and changes no state
/// other than remembering it was seen.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _pageCount = 3;
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pageCount - 1;

  Future<void> _next() async {
    if (!_isLast) {
      final reduce = MediaQuery.disableAnimationsOf(context);
      await _controller.nextPage(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    _finish();
  }

  void _finish() {
    OnboardingPrefs.markWelcomeSeen();
    Navigator.of(context).pushReplacementNamed(Routes.roleSelect);
  }

  void _login() {
    OnboardingPrefs.markWelcomeSeen();
    // Same path as the role-select "Log in" link: login opens on top of it.
    Navigator.of(context).pushReplacementNamed(Routes.roleSelect);
    Navigator.of(context).pushNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final pages = [
      _WelcomePage(
        illustration: const ArtworkImage(
          'assets/artwork/inclusive_travel_people_and_bus.png',
          aspectRatio: 710 / 439,
        ),
        title: context.t('onb1Title'),
        body: context.t('onb1Body'),
      ),
      _WelcomePage(
        illustration: const ArtworkImage(
          'assets/artwork/wheelchair_accessible_bus_ramp.png',
          aspectRatio: 278 / 251,
          zoom: 1.2,
        ),
        title: context.t('onb2Title'),
        body: context.t('onb2Body'),
      ),
      _WelcomePage(
        illustration: const ArtworkImage(
          'assets/artwork/volunteer_helping_elderly_passenger.png',
          aspectRatio: 306 / 251,
          zoom: 1.2,
        ),
        title: context.t('onb3Title'),
        body: context.t('onb3Body'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  // Kept laid out on the last page so the toggle stays put.
                  Visibility(
                    visible: !_isLast,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(
                        context.t('onbSkip'),
                        style: TextStyle(
                          color: palette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  LanguageToggle(
                    locale: state.locale,
                    onChanged: state.setLocale,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            _Dots(count: _pageCount, index: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
                    minimumSize: const Size.fromHeight(56),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _isLast
                              ? context.t('onbGetStarted')
                              : context.t('onbNext'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton(
                onPressed: _login,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: TextStyle(fontSize: 14, color: palette.muted),
                    children: [
                      TextSpan(text: '${context.t('haveAccount')} '),
                      TextSpan(
                        text: context.t('logIn'),
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.illustration,
    required this.title,
    required this.body,
  });

  final Widget illustration;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Fills the page and spreads the illustration and text over its height
    // (scrolls instead when large text makes the content taller).
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 8),
              illustration,
              const SizedBox(height: 24),
              Column(
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        height: 1.25,
                        color: palette.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '${index + 1} / $count',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? palette.accent : palette.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
