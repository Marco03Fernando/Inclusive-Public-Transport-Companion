import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/progress_steps.dart';

class SignupBasicScreen extends StatefulWidget {
  const SignupBasicScreen({super.key});

  @override
  State<SignupBasicScreen> createState() => _SignupBasicScreenState();
}

class _SignupBasicScreenState extends State<SignupBasicScreen> {
  late final _name = TextEditingController(text: context.read<AppState>().signupName);
  late final _phone = TextEditingController(text: context.read<AppState>().signupPhone);
  late final _dob = TextEditingController(text: context.read<AppState>().signupDob);
  late final _email = TextEditingController(text: context.read<AppState>().signupEmail);
  late final _password = TextEditingController(text: context.read<AppState>().signupPassword);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dob.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continue(BuildContext context) {
    context.read<AppState>().setSignupBasic(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          dob: _dob.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
    Navigator.of(context).pushReplacementNamed(Routes.signupAccess);
  }

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
          LabeledTextField(label: context.t('fullName'), controller: _name),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('phoneNumber'), controller: _phone),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('dob'), controller: _dob),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('emailLabel'), controller: _email),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('passwordLabel'), controller: _password, obscureText: true),
          const SizedBox(height: 28),
          PrimaryButton(
            label: context.t('continueBtn'),
            onPressed: () => _continue(context),
          ),
        ],
      ),
    );
  }
}
