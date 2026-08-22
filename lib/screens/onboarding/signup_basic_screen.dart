import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/progress_steps.dart';

class SignupBasicScreen extends StatelessWidget {
  const SignupBasicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppScaffold(
      routeName: Routes.signupBasic,
      title: context.t('signUp'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.roleSelect),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProgressSteps(step: 1),
          const SizedBox(height: 14),
          Text(
            context.t('yourDetails'),
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 20, color: palette.text),
          ),
          const SizedBox(height: 2),
          Text(context.t('personaliseNote'), style: TextStyle(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('fullName'), initialValue: 'Kamala Fernando'),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('phoneNumber'), initialValue: '+94 77 555 2211'),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('dob'), initialValue: '14 / 03 / 1958'),
          const SizedBox(height: 28),
          PrimaryButton(
            label: context.t('continueBtn'),
            onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.signupAccess),
          ),
        ],
      ),
    );
  }
}
