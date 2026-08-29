import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/living_pin_logo.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  bool _guestLoading = false;
  final _pinKey = GlobalKey<LivingPinLogoState>();

  Future<void> _continueAsGuest(BuildContext context) async {
    setState(() => _guestLoading = true);
    final ok = await context.read<AuthState>().continueAsGuest();
    if (!context.mounted) return;
    setState(() => _guestLoading = false);
    if (ok) Navigator.of(context).pushReplacementNamed(Routes.volunteerHome);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();

    Future<void> choose(AppRole role) async {
      await _pinKey.currentState?.playConfirm();
      if (!context.mounted) return;
      state.setRole(role);
      Navigator.of(context).pushReplacementNamed(Routes.signupBasic);
    }

    return AppScaffold(
      routeName: Routes.roleSelect,
      scrollableBody: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: LanguageToggle(locale: state.locale, onChanged: state.setLocale),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LivingPinLogo(key: _pinKey),
                    const SizedBox(height: 2),
                    Text(
                      'Colombo Pal',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 260,
                      child: Text(
                        context.t('appTagline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: palette.muted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.t('registeringAs'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.muted),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  title: context.t('rolePassenger'),
                  description: context.t('passengerDesc'),
                  onTap: () => choose(AppRole.passenger),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  title: context.t('roleVolunteer'),
                  description: context.t('volunteerDesc'),
                  onTap: () => choose(AppRole.volunteer),
                ),
                const SizedBox(height: 6),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed(Routes.login),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: palette.muted),
                        children: [
                          TextSpan(text: '${context.t('haveAccount')} '),
                          TextSpan(
                            text: context.t('logIn'),
                            style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _guestLoading ? null : () => _continueAsGuest(context),
                    child: Text(
                      _guestLoading ? context.t('loading') : context.t('continueAsGuest'),
                      style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.title, required this.description, required this.onTap});

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16, color: palette.text),
            ),
            const SizedBox(height: 3),
            Text(description, style: TextStyle(fontSize: 13, color: palette.muted)),
          ],
        ),
      ),
    );
  }
}
