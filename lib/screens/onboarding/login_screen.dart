import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/labeled_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final authState = context.read<AuthState>();
    final ok = await authState.signIn(_emailController.text.trim(), _passwordController.text);
    if (!context.mounted || !ok) return;
    final role = context.read<AppState>().role;
    Navigator.of(context).pushReplacementNamed(role == AppRole.passenger ? Routes.home : Routes.volunteerHome);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final authState = context.watch<AuthState>();
    return AppScaffold(
      routeName: Routes.login,
      title: context.t('logIn'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.roleSelect),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('logInTitle'),
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 20, color: palette.text),
          ),
          const SizedBox(height: 2),
          Text(context.t('logInNote'), style: TextStyle(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('emailLabel'), controller: _emailController),
          const SizedBox(height: 14),
          LabeledTextField(
            label: context.t('passwordLabel'),
            controller: _passwordController,
            obscureText: true,
          ),
          if (authState.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(authState.errorMessage!, style: TextStyle(fontSize: 12, color: palette.danger)),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
            label: authState.loading ? context.t('loading') : context.t('logIn'),
            onPressed: authState.loading ? null : () => _submit(context),
          ),
        ],
      ),
    );
  }
}
