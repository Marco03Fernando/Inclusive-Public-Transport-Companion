import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';

/// The floating emergency SOS button. Scaffold already raises the FAB above
/// a bottom nav bar when both are present, so no manual offset is needed.
///
/// A 64dp circle with "SOS" text inside, in the emergency colour. Tapping only OPENS the confirmation dialog — the alert itself
/// still needs the 3-second hold there, so it can't fire by accident.
/// Screen readers announce "Emergency SOS" plus a hint saying a
/// confirmation follows.
class SosButton extends StatelessWidget {
  const SosButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: context.t('sosA11yLabel'),
      hint: context.t('sosA11yHint'),
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox.square(
        dimension: 64,
        child: FloatingActionButton(
          heroTag: 'sos',
          onPressed: onPressed,
          backgroundColor: palette.danger,
          foregroundColor: palette.onDanger,
          elevation: palette.isHighContrast ? 0 : 4,
          shape: CircleBorder(
            side: palette.isHighContrast
                ? BorderSide(color: palette.text, width: 2)
                : BorderSide.none,
          ),
          child: Text(
            'SOS',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
