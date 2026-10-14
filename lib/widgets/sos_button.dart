import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// The floating red SOS button. Scaffold already raises the FAB above a
/// bottom nav bar when both are present, so no manual offset is needed.
class SosButton extends StatelessWidget {
  const SosButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: palette.danger,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      child: Text('SOS', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}
