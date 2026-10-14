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
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final authState = context.read<AuthState>()..clearError();
    final email = _emailController.text.trim();
    setState(() {
      _localError = !email.contains('@')
          ? 'Please enter a valid email.'
          : _passwordController.text.isEmpty
          ? 'Please enter your password.'
          : null;
    });
    if (_localError != null) return;

    final ok = await authState.signIn(email, _passwordController.text);
    if (!context.mounted || !ok) return;
    // Routes by users/{uid}.role — admins land on the admin dashboard.
    final role = context.read<AppState>().role;
    Navigator.of(context).pushReplacementNamed(Routes.homeFor(role));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final authState = context.watch<AuthState>();
    final error = _localError ?? authState.errorMessage;
    return AppScaffold(
      routeName: Routes.login,
      title: context.t('logIn'),
      onBack: () =>
          Navigator.of(context).pushReplacementNamed(Routes.roleSelect),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('logInTitle'),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.t('logInNote'),
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: context.t('emailLabel'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: context.t('passwordLabel'),
            controller: _passwordController,
            obscureText: true,
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error, style: TextStyle(fontSize: 12, color: palette.danger)),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
            label: authState.loading
                ? context.t('loading')
                : context.t('logIn'),
            onPressed: authState.loading ? null : () => _submit(context),
          ),
        ],
      ),
    );
  }
}
