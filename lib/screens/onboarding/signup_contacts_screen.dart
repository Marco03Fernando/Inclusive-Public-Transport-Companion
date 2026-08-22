import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/contact_card.dart';
import '../../widgets/dotted_add_button.dart';
import '../../widgets/progress_steps.dart';

class SignupContactsScreen extends StatelessWidget {
  const SignupContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final role = context.watch<AppState>().role;
    return AppScaffold(
      routeName: Routes.signupContacts,
      title: context.t('signUp'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.signupAccess),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProgressSteps(step: 3),
          const SizedBox(height: 14),
          Text(
            context.t('contactsTitle'),
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 20, color: palette.text),
          ),
          const SizedBox(height: 2),
          Text(context.t('contactsNote'), style: TextStyle(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 14),
          for (var i = 0; i < mockContacts.length; i++) ...[
            ContactCard(contact: mockContacts[i], heading: '${context.t('contactWord')} ${i + 1}'),
            const SizedBox(height: 10),
          ],
          DottedAddButton(label: context.t('addAnotherContact')),
          const SizedBox(height: 28),
          PrimaryButton(
            label: context.t('finishSetup'),
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              role == AppRole.passenger ? Routes.home : Routes.volunteerHome,
            ),
          ),
        ],
      ),
    );
  }
}
