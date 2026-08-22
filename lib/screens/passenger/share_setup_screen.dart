import 'package:flutter/material.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/contact_card.dart';

class ShareSetupScreen extends StatefulWidget {
  const ShareSetupScreen({super.key});

  @override
  State<ShareSetupScreen> createState() => _ShareSetupScreenState();
}

class _ShareSetupScreenState extends State<ShareSetupScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
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
          for (var i = 0; i < mockContacts.length; i++) ...[
            ContactPickerRow(
              contact: mockContacts[i],
              selected: _selected == i,
              onTap: () => setState(() => _selected = i),
            ),
            const SizedBox(height: 10),
          ],
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
}
