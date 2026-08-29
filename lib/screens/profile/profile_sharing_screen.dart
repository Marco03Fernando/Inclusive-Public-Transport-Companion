import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/toggle_row.dart';

class ProfileSharingScreen extends StatelessWidget {
  const ProfileSharingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    return AppScaffold(
      routeName: Routes.profileSharing,
      title: context.t('locationSharingTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.profileHome),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleRow(
            title: context.t('autoShareTitle'),
            subtitle: context.t('autoShareNote'),
            value: state.autoShare,
            onChanged: (_) => state.toggleAutoShare(),
          ),
          const SizedBox(height: 14),
          Text(
            context.t('sharingHistory'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
          ),
          const SizedBox(height: 10),
          const DemoDataBadge(),
          for (final entry in mockSharingHistory) ...[
            NoteCard(child: Text(entry)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
