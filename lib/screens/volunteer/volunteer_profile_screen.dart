import 'package:flutter/material.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/settings_link_row.dart';

class VolunteerProfileScreen extends StatelessWidget {
  const VolunteerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      routeName: Routes.volunteerProfile,
      scrollableBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(initials: 'RJ', name: 'Ruwan Jayasuriya', roleLabel: context.t('roleVolunteer')),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsLinkRow(
                    label: context.t('activeArea'),
                    onTap: () {},
                    trailingText: 'Colombo 3–6',
                  ),
                  const SizedBox(height: 10),
                  SettingsLinkRow(label: context.t('notificationPrefs'), onTap: () {}),
                  const SizedBox(height: 18),
                  TextDangerButton(label: context.t('logOut'), onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
