import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/settings_link_row.dart';
import '../../widgets/theme_mode_selector.dart';

class VolunteerProfileScreen extends StatelessWidget {
  const VolunteerProfileScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    await context.read<AuthState>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.roleSelect, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final profile = context.watch<AuthState>().profile;
    final hasRealName = profile?.name.isNotEmpty ?? false;
    return AppScaffold(
      routeName: Routes.volunteerProfile,
      scrollableBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(
              initials: hasRealName ? profile!.initials : 'RJ',
              name: hasRealName ? profile!.name : 'Ruwan Jayasuriya',
              roleLabel: context.t('roleVolunteer'),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!hasRealName) ...[const DemoDataBadge(), const SizedBox(height: 4)],
                  const DemoDataBadge(),
                  const SizedBox(height: 8),
                  SettingsLinkRow(
                    label: context.t('activeArea'),
                    onTap: () {},
                    trailingText: 'Colombo 3–6',
                  ),
                  const SizedBox(height: 10),
                  SettingsLinkRow(label: context.t('notificationPrefs'), onTap: () {}),
                  const SizedBox(height: 10),
                  SettingsLinkRow(
                    label: context.t('assistanceRequestsTitle'),
                    onTap: () => Navigator.of(context).pushReplacementNamed(Routes.volunteerAssistanceRequests),
                  ),
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
