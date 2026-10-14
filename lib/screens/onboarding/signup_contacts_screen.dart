import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/contact.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/contact_card.dart';
import '../../widgets/contact_form_sheet.dart';
import '../../widgets/dotted_add_button.dart';
import '../../widgets/progress_steps.dart';

class SignupContactsScreen extends StatefulWidget {
  const SignupContactsScreen({super.key});

  @override
  State<SignupContactsScreen> createState() => _SignupContactsScreenState();
}

class _SignupContactsScreenState extends State<SignupContactsScreen> {
  final _userProfileService = UserProfileService();
  final List<Contact> _contacts = [];

  Future<void> _addContact() async {
    final contact = await showContactFormSheet(context);
    if (contact != null) setState(() => _contacts.add(contact));
  }

  Future<void> _finish(BuildContext context) async {
    final appState = context.read<AppState>();
    final authState = context.read<AuthState>();
    final ok = await authState.signUpAndCreateProfile(
      email: appState.signupEmail,
      password: appState.signupPassword,
      name: appState.signupName,
      phone: appState.signupPhone,
      dob: appState.signupDob,
      role: appState.role,
      accessNeeds: appState.accessNeeds,
    );
    if (!context.mounted) return;
    if (!ok) return;

    for (final contact in _contacts) {
      await _userProfileService.addContact(authState.uid!, contact);
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(
      appState.role == AppRole.passenger ? Routes.home : Routes.volunteerHome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final authState = context.watch<AuthState>();
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
          for (var i = 0; i < _contacts.length; i++) ...[
            ContactCard(
              contact: _contacts[i],
              heading: '${context.t('contactWord')} ${i + 1}',
              trailing: IconButton(
                icon: Icon(Icons.close, size: 18, color: palette.muted),
                onPressed: () => setState(() => _contacts.removeAt(i)),
              ),
            ),
            const SizedBox(height: 10),
          ],
          DottedAddButton(label: context.t('addAnotherContact'), onTap: _addContact),
          if (authState.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(authState.errorMessage!, style: TextStyle(fontSize: 12, color: palette.danger)),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
            label: authState.loading ? context.t('loading') : context.t('finishSetup'),
            onPressed: authState.loading ? null : () => _finish(context),
          ),
        ],
      ),
    );
  }
}
