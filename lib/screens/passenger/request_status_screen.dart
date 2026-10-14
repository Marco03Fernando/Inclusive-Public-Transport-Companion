import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/assistance_request.dart';
import '../../services/assistance_request_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';

class RequestStatusScreen extends StatelessWidget {
  const RequestStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final uid = context.watch<AuthState>().uid;
    final service = AssistanceRequestService();

    return AppScaffold(
      routeName: Routes.requestStatus,
      title: context.t('requestAssistanceTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.profileHome),
      body: uid == null
          ? const SizedBox.shrink()
          : StreamBuilder<List<AssistanceRequest>>(
              stream: service.watchRequestsForPassenger(uid),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? const [];
                if (requests.isEmpty) {
                  return Text(context.t('noActiveRequest'), style: TextStyle(fontSize: 13, color: palette.muted));
                }
                final request = requests.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: palette.surface2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        context.t(assistanceStatusLabelKeys[request.status]!),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.text),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(context.t(assistanceTypeLabelKeys[request.type]!),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.text)),
                    if (request.note != null) ...[
                      const SizedBox(height: 6),
                      Text(request.note!, style: TextStyle(fontSize: 13, color: palette.muted)),
                    ],
                    if (request.status == AssistanceStatus.accepted && request.volunteerName != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        '${request.volunteerName} ${context.t('volunteerOnTheWay')}',
                        style: TextStyle(fontSize: 13, color: palette.text),
                      ),
                    ],
                    if (request.status == AssistanceStatus.pending) ...[
                      const SizedBox(height: 28),
                      SecondaryButton(
                        label: context.t('cancelRequestBtn'),
                        onPressed: () => service.cancelRequest(request.id),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

