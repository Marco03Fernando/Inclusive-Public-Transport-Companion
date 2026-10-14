import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic colors lifted from the design reference's CSS custom properties
/// (`--rail`, `--accent`, `--danger`, ...). Exposed as a [ThemeExtension] so
/// every screen reads colors the same way the design reads CSS variables:
/// `context.palette.accent` instead of hardcoded hex values.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.rail,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warn,
    required this.warnSoft,
    required this.onAccent,
    required this.cta,
    required this.ctaSoft,
    required this.onCta,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.shadow,
  });

  final Color rail;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color muted;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warn;
  final Color warnSoft;
  final Color onAccent;

  /// The warm call-to-action color — every tappable primary action (buttons,
  /// the active bottom-nav tab, selection states) uses this, while [accent]
  /// stays the cooler brand/decorative teal (hero surfaces, icons, links).
  final Color cta;
  final Color ctaSoft;
  final Color onCta;

  /// Gradient stops for elevated hero surfaces (greeting header, profile
  /// header). Distinct from [accent] so a saturated teal fill doesn't have
  /// to double as icon/text-on-surface color too.
  final Color heroGradientStart;
  final Color heroGradientEnd;

  /// Ambient shadow color for elevated cards — already tuned per-brightness
  /// so callers just do `BoxShadow(color: palette.shadow, ...)`.
  final Color shadow;

  static const light = AppPalette(
    rail: Color(0xFFF6F5F2),
    bg: Color(0xFFF9F8F5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0EEEA),
    text: Color(0xFF1C1A17),
    muted: Color(0xFF65635D),
    border: Color(0xFFDCDBD6),
    accent: Color(0xFF0E7C86),
    accentSoft: Color(0xFFCFEFEA),
    success: Color(0xFF298646),
    successSoft: Color(0xFFD4F1D8),
    danger: Color(0xFFC53637),
    dangerSoft: Color(0xFFFFDCD7),
    warn: Color(0xFFBB7400),
    warnSoft: Color(0xFFFEE3C5),
    onAccent: Color(0xFFFFFFFF),
    cta: Color(0xFFFF6A4D),
    ctaSoft: Color(0xFFFFE3DB),
    onCta: Color(0xFFFFFFFF),
    heroGradientStart: Color(0xFF0E7C86),
    heroGradientEnd: Color(0xFF135F68),
    shadow: Color(0x1F1C1A17),
  );

  static const dark = AppPalette(
    rail: Color(0xFF12171B),
    bg: Color(0xFF0B1015),
    surface: Color(0xFF181E23),
    surface2: Color(0xFF21272D),
    text: Color(0xFFF0EEEB),
    muted: Color(0xFF94999E),
    border: Color(0xFF30363C),
    accent: Color(0xFF2FB5D8),
    accentSoft: Color(0xFF07333F),
    success: Color(0xFF63B376),
    successSoft: Color(0xFF1A3520),
    danger: Color(0xFFE3645E),
    dangerSoft: Color(0xFF4F1A18),
    warn: Color(0xFFDBA15C),
    warnSoft: Color(0xFF462D0B),
    onAccent: Color(0xFF00222B),
    cta: Color(0xFFFF8562),
    ctaSoft: Color(0xFF3A1C14),
    onCta: Color(0xFF2B0D06),
    heroGradientStart: Color(0xFF1C7986),
    heroGradientEnd: Color(0xFF0A363D),
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith({
    Color? rail,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? text,
    Color? muted,
    Color? border,
    Color? accent,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? danger,
    Color? dangerSoft,
    Color? warn,
    Color? warnSoft,
    Color? onAccent,
    Color? cta,
    Color? ctaSoft,
    Color? onCta,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? shadow,
  }) {
    return AppPalette(
      rail: rail ?? this.rail,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      onAccent: onAccent ?? this.onAccent,
      cta: cta ?? this.cta,
      ctaSoft: ctaSoft ?? this.ctaSoft,
      onCta: onCta ?? this.onCta,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      rail: Color.lerp(rail, other.rail, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      cta: Color.lerp(cta, other.cta, t)!,
      ctaSoft: Color.lerp(ctaSoft, other.ctaSoft, t)!,
      onCta: Color.lerp(onCta, other.onCta, t)!,
      heroGradientStart: Color.lerp(heroGradientStart, other.heroGradientStart, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(AppPalette palette) {
    final base = GoogleFonts.publicSansTextTheme();
    final heading = GoogleFonts.manropeTextTheme();
    return base
        .copyWith(
          displayLarge: heading.displayLarge,
          displayMedium: heading.displayMedium,
          displaySmall: heading.displaySmall,
          headlineLarge: heading.headlineLarge,
          headlineMedium: heading.headlineMedium,
          headlineSmall: heading.headlineSmall,
          titleLarge: heading.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium: heading.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: heading.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        )
        .apply(bodyColor: palette.text, displayColor: palette.text);
  }

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.cta,
      onPrimary: palette.onCta,
      secondary: palette.accent,
      onSecondary: palette.onAccent,
      error: palette.danger,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.bg,
      canvasColor: palette.bg,
      dividerColor: palette.border,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme(palette),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: palette.text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: TextStyle(color: palette.muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.cta, width: 1.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        shadowColor: palette.shadow,
      ),
      extensions: [palette],
    );
  }

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
}
