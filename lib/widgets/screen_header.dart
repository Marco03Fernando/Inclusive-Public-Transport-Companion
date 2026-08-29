import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// The pill back-button + title header used on every non-home,
/// non-onboarding-landing screen. Implemented as a [PreferredSizeWidget] so
/// it can be dropped straight into `Scaffold.appBar`.
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      color: palette.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: SizedBox(
                width: 34,
                height: 34,
                child: OutlinedButton(
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: palette.surface,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Icon(Icons.chevron_left, size: 20, color: palette.text),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
