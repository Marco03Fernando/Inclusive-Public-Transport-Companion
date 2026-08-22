import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/access_need_tile.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/progress_steps.dart';

class SignupAccessScreen extends StatelessWidget {
  const SignupAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    return AppScaffold(
      routeName: Routes.signupAccess,
      title: context.t('signUp'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.signupBasic),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProgressSteps(step: 2),
          const SizedBox(height: 14),
          Text(
            context.t('accessTitle'),
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 20, color: palette.text),
          ),
          const SizedBox(height: 2),
          Text(context.t('accessNote'), style: TextStyle(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 14),
          for (final need in state.accessNeeds) ...[
            AccessNeedTile(
              label: context.t(need.labelKey),
              checked: need.checked,
              onTap: () => state.toggleAccessNeed(need.id),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            context.t('medicalNotesLabel'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
          ),
          const SizedBox(height: 6),
          LabeledTextArea(placeholder: context.t('medicalPlaceholder'), label: ''),
          const SizedBox(height: 28),
          PrimaryButton(
            label: context.t('continueBtn'),
            onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.signupContacts),
          ),
        ],
      ),
    );
  }
}
