import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/google_route.dart';
import '../../services/polyline_decoder.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/condition_tile.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/route_step_item.dart';

class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({
    super.key,
    required this.route,
  });

  final GoogleRoute route;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final routePoints =
        PolylineDecoder.decode(widget.route.encodedPolyline);

    final routePolyline = Polyline(
      polylineId: const PolylineId('selected_route'),
      points: routePoints,
      width: 5,
    );

    return AppScaffold(
      routeName: Routes.planDetail,
      title: 'Bus 138 + Coastal Line',
      scrollableBody: false,
      onBack: () =>
          Navigator.of(context).pushReplacementNamed(Routes.planResults),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(6.9271, 79.8612),
                  zoom: 13,
                ),
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
                polylines: {
                  routePolyline,
                },
                onMapCreated: (controller) {

                  if (routePoints.isEmpty) {
                    return;
                  }

                  final bounds = _getRouteBounds(routePoints);

                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(
                      bounds,
                      60,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t('stepByStep'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const DemoDataBadge(),
                  for (var i = 0; i < mockRouteSteps.length; i++)
                    RouteStepItem(
                      step: mockRouteSteps[i],
                      isLast: i == mockRouteSteps.length - 1,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    context.t('reportedAlongRoute'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const DemoDataBadge(),
                  for (final c in mockRouteConditions) ...[
                    ConditionTile(report: c),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLngBounds _getRouteBounds(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

