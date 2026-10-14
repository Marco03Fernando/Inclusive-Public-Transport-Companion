import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/assistance_request.dart';
import '../../services/assistance_request_service.dart';
import '../../services/location_service.dart';
import '../../widgets/action_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';

class AssistanceRequestsScreen extends StatefulWidget {
  const AssistanceRequestsScreen({super.key});

  @override
  State<AssistanceRequestsScreen> createState() => _AssistanceRequestsScreenState();
}

class _AssistanceRequestsScreenState extends State<AssistanceRequestsScreen> {
  final _requestService = AssistanceRequestService();
  final _locationService = LocationService();
  late final Future<Position?> _myPositionFuture = _locationService.getCurrentPosition();

  List<AssistanceRequest> _sorted(List<AssistanceRequest> requests, Position? myPosition) {
    final withDistance = requests.map((r) {
      final distance = (myPosition != null && r.lat != null && r.lng != null)
          ? LocationService.distanceKm(myPosition.latitude, myPosition.longitude, r.lat!, r.lng!)
          : double.infinity;
      return (request: r, distance: distance);
    }).toList();
    withDistance.sort((a, b) => a.distance.compareTo(b.distance));
    return withDistance.map((e) => e.request).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final authState = context.watch<AuthState>();
    final uid = authState.uid;

    return AppScaffold(
      routeName: Routes.volunteerAssistanceRequests,
      title: context.t('assistanceRequestsTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.volunteerProfile),
      body: uid == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<List<AssistanceRequest>>(
                  stream: _requestService.watchAcceptedByVolunteer(uid),
                  builder: (context, snapshot) {
                    final accepted = snapshot.data ?? const [];
                    if (accepted.isEmpty) return const SizedBox.shrink();
                    final request = accepted.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.t('myAcceptedRequestTitle'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
                          ),
                          const SizedBox(height: 8),
                          ActionCard(
                            title: request.passengerName,
                            description: context.t(assistanceTypeLabelKeys[request.type]!),
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          SecondaryButton(
                            label: context.t('markCompleteBtn'),
                            onPressed: () => _requestService.completeRequest(request.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Text(
                  context.t('openRequestsTitle'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
                ),
                const SizedBox(height: 8),
                FutureBuilder<Position?>(
                  future: _myPositionFuture,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<List<AssistanceRequest>>(
                      stream: _requestService.watchOpenRequests(),
                      builder: (context, snapshot) {
                        final requests = _sorted(snapshot.data ?? const [], positionSnapshot.data);
                        if (requests.isEmpty) {
                          return Text(context.t('noOpenRequests'), style: TextStyle(fontSize: 13, color: palette.muted));
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final request in requests) ...[
                              ActionCard(
                                title: request.passengerName,
                                description: context.t(assistanceTypeLabelKeys[request.type]!),
                                onTap: () {},
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 10),
                                child: PrimaryButton(
                                  label: context.t('acceptBtn'),
                                  onPressed: () => _requestService.acceptRequest(
                                    request.id,
                                    uid,
                                    authState.profile?.name.isNotEmpty ?? false
                                        ? authState.profile!.name
                                        : authState.firebaseUser?.displayName ??
                                            authState.firebaseUser?.email ??
                                            'Volunteer',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}
