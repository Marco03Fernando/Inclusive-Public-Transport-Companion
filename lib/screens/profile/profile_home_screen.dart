import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/settings_link_row.dart';
import '../../widgets/theme_mode_selector.dart';

class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    await context.read<AuthState>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.roleSelect, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final languageLabel =
        '${context.t('languageWord')}: ${state.locale == AppLocale.en ? context.t('englishWord') : context.t('sinhalaWord')}';

    return AppScaffold(
      routeName: Routes.profileHome,
      scrollableBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(initials: 'KF', name: 'Kamala Fernando', roleLabel: context.t('rolePassenger')),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsLinkRow(
                    label: context.t('emergencyContactsTitle'),
                    onTap: () => Navigator.of(context).pushReplacementNamed(Routes.profileContacts),
                  ),
                  const SizedBox(height: 10),
                  SettingsLinkRow(
                    label: context.t('accessPrefsTitle'),
                    onTap: () => Navigator.of(context).pushReplacementNamed(Routes.profileAccess),
                  ),
                  const SizedBox(height: 10),
                  SettingsLinkRow(
                    label: context.t('locationSharingTitle'),
                    onTap: () => Navigator.of(context).pushReplacementNamed(Routes.profileSharing),
                  ),
                  const SizedBox(height: 10),
                  SettingsLinkRow(
                    label: context.t('requestAssistanceTitle'),
                    onTap: () => Navigator.of(context).pushReplacementNamed(Routes.requestAssistance),
                  ),
                  const SizedBox(height: 10),
                  SettingsLinkRow(label: languageLabel, onTap: state.toggleLocale),
                  const SizedBox(height: 20),
                  Text(
                    context.t('appearanceTitle'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
                  ),
                  const SizedBox(height: 10),
                  ThemeModeSelector(mode: state.themeMode, onChanged: state.setThemeMode),
                  const SizedBox(height: 18),
                  TextDangerButton(label: context.t('logOut'), onPressed: () => _logOut(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
