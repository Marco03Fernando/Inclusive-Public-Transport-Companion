import 'package:flutter/material.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/contact_card.dart';
import '../../widgets/dotted_add_button.dart';

class ProfileContactsScreen extends StatelessWidget {
  const ProfileContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppScaffold(
      routeName: Routes.profileContacts,
      title: context.t('emergencyContactsTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.profileHome),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.t('emergencyContactsNote'), style: TextStyle(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 12),
          for (final contact in mockContacts) ...[
            ContactCard(
              contact: contact,
              trailing: Text(
                context.t('editWord'),
                style: TextStyle(fontSize: 12, color: palette.accent, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
          ],
          DottedAddButton(label: context.t('addContact')),
        ],
      ),
    );
  }
}
