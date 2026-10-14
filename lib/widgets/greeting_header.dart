import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// Compact welcome header atop Home and Volunteer Home: greeting, display
/// name, optional role pill and avatar initials, and optional trailing
/// [actions] (e.g. Read Aloud, Accessibility shortcut).
///
/// A flat brand-teal surface (no gradient or glow) with [AppPalette.onHero]
/// text.
///
/// Full-bleed: when placed at the very top of a screen that does NOT wrap
/// it in a top SafeArea (`AppScaffold(safeAreaTop: false)`), the teal runs
/// up behind the status bar and the content is pushed down by exactly the
/// status-bar inset ([MediaQuery.paddingOf]). Inside a SafeArea that inset
/// is already 0, so it also works there unchanged. Status-bar icons are set
/// to light to stay readable on the dark teal. The greeting and name are read as one heading ("Welcome back,
/// Ruwan Jayasuriya, Volunteer"); the avatar is decorative.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.greeting,
    required this.name,
    this.roleLabel,
    this.initials,
    this.actions = const [],
  });

  final String greeting;
  final String name;
  final String? roleLabel;
  final String? initials;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = palette.onHero;
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 16, 8, 20),
        decoration: BoxDecoration(
          color: palette.heroGradientStart,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (initials != null && initials!.isNotEmpty) ...[
              ExcludeSemantics(
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: fg.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    initials!,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: fg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: MergeSemantics(
                child: Semantics(
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: fg.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                          height: 1.2,
                          color: fg,
                        ),
                      ),
                      if (roleLabel != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: fg.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volunteer_activism_rounded,
                                size: 14,
                                color: fg,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  roleLabel!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: fg,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 4),
              IconButtonTheme(
                data: IconButtonThemeData(
                  style: IconButton.styleFrom(foregroundColor: fg),
                ),
                // Top-aligned so a long, wrapping name never pushes the
                // buttons around.
                child: Row(mainAxisSize: MainAxisSize.min, children: actions),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The centered avatar + name + role pill atop the profile screens.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.initials,
    required this.name,
    required this.roleLabel,
  });

  final String initials;
  final String name;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              initials,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: palette.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
