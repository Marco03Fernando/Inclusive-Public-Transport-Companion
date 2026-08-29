import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/contact.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/contact_card.dart';
import '../../widgets/demo_data_badge.dart';

class ShareSetupScreen extends StatefulWidget {
  const ShareSetupScreen({super.key});

  @override
  State<ShareSetupScreen> createState() => _ShareSetupScreenState();
}

class _ShareSetupScreenState extends State<ShareSetupScreen> {
  final _service = UserProfileService();
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final uid = context.watch<AuthState>().uid;
    return AppScaffold(
      routeName: Routes.shareSetup,
      title: context.t('shareJourney'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.home),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.t('shareIntro'), style: TextStyle(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 14),
          Text(
            context.t('shareWith'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
          ),
          const SizedBox(height: 10),
          if (uid == null)
            _contactPickerList(mockContacts, isDemo: true)
          else
            StreamBuilder<List<Contact>>(
              stream: _service.watchContacts(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final realContacts = snapshot.data ?? const [];
                final usingDemo = realContacts.isEmpty;
                return _contactPickerList(usingDemo ? mockContacts : realContacts, isDemo: usingDemo);
              },
            ),
          NoteCard(
            tint: context.palette.surface2,
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: palette.text),
                children: [
                  TextSpan(text: '${context.t('journeyLabel')} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: 'Nugegoda Bus Stand → Bambalapitiya via Bus 138 + Coastal Line'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: context.t('startSharing'),
            onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.shareActive),
          ),
        ],
      ),
    );
  }

  Widget _contactPickerList(List<Contact> contacts, {required bool isDemo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDemo) const DemoDataBadge(),
        for (var i = 0; i < contacts.length; i++) ...[
          ContactPickerRow(
            contact: contacts[i],
            selected: _selected == i,
            onTap: () => setState(() => _selected = i),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
