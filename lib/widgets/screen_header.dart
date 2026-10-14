import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';

/// The pill back-button + title header used on every non-home,
/// non-onboarding-landing screen. Implemented as a [PreferredSizeWidget] so
/// it can be dropped straight into `Scaffold.appBar`.
///
/// The back button is a full 48x48 touch target announced as "Back"; the
/// title is announced as a heading. Long titles ellipsize rather than
/// overflow at large text sizes (screen readers still read the full title).
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final VoidCallback? onBack;

  /// Trailing buttons, e.g. a Read Aloud button.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      color: palette.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: palette.cardOutline,
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Tooltip(
                  message: context.t('back'),
                  child: OutlinedButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: palette.surface,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      size: 24,
                      color: palette.text,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: palette.text,
                  ),
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
