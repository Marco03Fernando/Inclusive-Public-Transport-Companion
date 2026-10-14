import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../core/localization/locale.dart';
import '../core/state/accessibility_settings.dart';
import '../core/theme/app_theme.dart';
import 'buttons.dart';

/// Branded startup screen [AuthGate] shows while Firebase starts and the
/// saved session's role is resolved — the app's only startup loading state.
///
/// It continues the native splash rather than replacing it: the native
/// splash shows the ColomboPal symbol (`colombopal_icon.png`) centred at a
/// fixed size, and the full logo shares that artwork pixel-for-pixel, so
/// this screen draws the logo with its symbol exactly over the native one.
/// The native → Flutter hand-off is therefore invisible; the only change is
/// a single fade that brings in the wordmark/tagline and the loading
/// status underneath. Nothing waits for it — [AuthGate] swaps this widget
/// out the moment startup finishes.
///
/// With the OS "remove animations" / reduce-motion setting or a screen
/// reader on, everything is shown at once with no fade. The logo is one
/// static semantics node; a startup failure is announced and offers
/// "Try again".
class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, this.failed = false, this.onRetry});

  /// Firebase could not start; shows the error + [onRetry] instead of the
  /// loading indicator.
  final bool failed;
  final VoidCallback? onRetry;

  /// Same white as the native splash and the logo's own (opaque) canvas,
  /// in light and dark mode alike.
  static const background = Colors.white;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  // Pre-sized copies (1x–4x) of colombopal_logo.png at exactly the size it
  // is drawn, so startup decodes ≤ 944 px instead of the 2000 px original.
  static const _logo = AssetImage(
    'assets/branding/startup/colombopal_logo.png',
  );

  // ---- Geometry shared with the native splash ----
  // The native splash draws the 1672 px icon canvas at 197.25 dp (it fills
  // 789/1152 of the 288 dp splash image, see colombopal_icon_padded.png),
  // centred on screen. The logo uses the same pixel scale, with the icon
  // canvas at (164, 0) inside its 2000 px canvas — so the logo's horizontal
  // centre and the icon's line up, and icon-canvas y = 836 px sits on the
  // screen's vertical centre.
  static const _dpPerPx = 197.25 / 1672;
  static const _logoSize = 2000 * _dpPerPx;
  static const _logoTopAboveCentre = 836 * _dpPerPx;

  /// Logo rows (as a fraction of its height): the symbol ends at 1346 px
  /// and the wordmark starts at 1390 px; the tagline ends at 1545 px.
  static const _wordmarkStart = 1368 / 2000;
  static const _wordmarkEnd = 1560 / 2000;

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _revealOpacity = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeOut,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduceMotion) _reveal.value = 1;
    // `main()` holds the native splash; release it once the logo is
    // decoded, so the first Flutter frame already shows it (no blank frame,
    // no image pop-in).
    precacheImage(_logo, context).whenComplete(() {
      FlutterNativeSplash.remove();
      if (mounted && !reduceMotion) _reveal.forward();
    });
  }

  @override
  void didUpdateWidget(StartupSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.failed && !oldWidget.failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _announceFailure());
    }
  }

  @override
  void dispose() {
    // Never leave the native splash covering the app, even if startup
    // finished before the logo was decoded.
    FlutterNativeSplash.remove();
    _reveal.dispose();
    super.dispose();
  }

  void _announceFailure() {
    if (!mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      '${context.t('startupErrorTitle')}. ${context.t('startupErrorBody')}',
      Directionality.of(context),
      assertiveness: Assertiveness.assertive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final highContrast =
        context.select<AccessibilitySettings, bool>((a) => a.highContrast) ||
        MediaQuery.highContrastOf(context);

    return Theme(
      data: highContrast ? AppTheme.highContrastLight : AppTheme.light,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Material(
          color: StartupSplash.background,
          // Laid out against the full screen (not the safe area), exactly
          // like the native splash, so the symbol doesn't shift.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoLeft = (constraints.maxWidth - _logoSize) / 2;
              final logoTop = constraints.maxHeight / 2 - _logoTopAboveCentre;
              final statusTop = (logoTop + _logoSize * _wordmarkEnd + 16).clamp(
                0.0,
                constraints.maxHeight,
              );
              return Stack(
                children: [
                  Positioned(
                    left: logoLeft,
                    top: logoTop,
                    width: _logoSize,
                    height: _logoSize,
                    child: _buildLogo(context),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: statusTop,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      // Scrolls instead of overflowing at very large text
                      // sizes or in landscape.
                      child: SingleChildScrollView(
                        child: widget.failed
                            ? _StartupError(onRetry: widget.onRetry)
                            : FadeTransition(
                                opacity: _revealOpacity,
                                child: const _StartupProgress(),
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    const image = Image(
      image: _logo,
      width: _logoSize,
      height: _logoSize,
      excludeFromSemantics: true,
    );
    return Semantics(
      image: true,
      label: context.t('startupLogoLabel'),
      child: ExcludeSemantics(
        child: Stack(
          children: [
            // The symbol — identical to, and on top of, the native splash.
            ClipRect(
              clipper: const _BandClipper(0, _wordmarkStart),
              child: image,
            ),
            // The wordmark + tagline fade in beneath it.
            FadeTransition(
              opacity: _revealOpacity,
              child: ClipRect(
                clipper: const _BandClipper(_wordmarkStart, 1),
                child: image,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clips to a horizontal band, [top]–[bottom] as fractions of the height.
class _BandClipper extends CustomClipper<Rect> {
  const _BandClipper(this.top, this.bottom);

  final double top;
  final double bottom;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * top, size.width, size.height * bottom);

  @override
  bool shouldReclip(_BandClipper oldClipper) =>
      oldClipper.top != top || oldClipper.bottom != bottom;
}

class _StartupProgress extends StatelessWidget {
  const _StartupProgress();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = context.t('startupLoading');
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.accent,
                backgroundColor: palette.accentSoft,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined, size: 32, color: palette.danger),
            const SizedBox(height: 12),
            Text(
              context.t('startupErrorTitle'),
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.t('startupErrorBody'),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: context.t('tryAgain'), onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
