import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// The accent-colored, rounded-bottom banner atop Home and Volunteer Home.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: TextStyle(fontSize: 13, color: palette.onAccent.withValues(alpha: 0.85))),
          const SizedBox(height: 2),
          Text(
            name,
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 22, color: palette.onAccent),
          ),
        ],
      ),
    );
  }
}

/// The centered avatar + name + role pill atop the profile screens.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.initials, required this.name, required this.roleLabel});

  final String initials;
  final String name;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: palette.border))),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
            child: Text(
              initials,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 22, color: palette.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 17, color: palette.text)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(999)),
            child: Text(
              roleLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.accent),
            ),
          ),
        ],
      ),
    );
  }
}
