import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';

class ReportConfirmScreen extends StatelessWidget {
  const ReportConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final origin = state.role == AppRole.passenger ? Routes.home : Routes.volunteerHome;

    return AppScaffold(
      routeName: Routes.reportConfirm,
      scrollableBody: false,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: palette.successSoft, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 28, color: palette.success),
            ),
            const SizedBox(height: 14),
            Text(
              context.t('reportSubmitted'),
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 19, color: palette.text),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 260,
              child: Text(
                context.t('reportSubmittedNote'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: palette.muted, height: 1.5),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: palette.warnSoft, borderRadius: BorderRadius.circular(999)),
              child: Text(
                context.t('underReview'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.warn),
              ),
            ),
            const SizedBox(height: 14),
            SecondaryButton(
              label: context.t('viewMyReports'),
              onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.reportMine),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: context.t('backToHomeLabel'),
              onPressed: () => Navigator.of(context).pushReplacementNamed(origin),
            ),
          ],
        ),
      ),
    );
  }
}
