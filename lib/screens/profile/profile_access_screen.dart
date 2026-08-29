import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/app_state.dart';
import '../../core/state/auth_state.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/access_need_tile.dart';
import '../../widgets/app_scaffold.dart';

class ProfileAccessScreen extends StatelessWidget {
  const ProfileAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final uid = context.watch<AuthState>().uid;

    void toggle(String id) {
      state.toggleAccessNeed(id);
      if (uid != null) UserProfileService().updateAccessNeeds(uid, state.accessNeeds);
    }

    return AppScaffold(
      routeName: Routes.profileAccess,
      title: context.t('accessPrefsTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.profileHome),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final need in state.accessNeeds) ...[
            AccessNeedTile(
              label: context.t(need.labelKey),
              checked: need.checked,
              onTap: () => toggle(need.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
