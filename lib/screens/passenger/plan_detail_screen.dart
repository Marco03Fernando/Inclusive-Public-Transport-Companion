import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/google_route.dart';
import '../../models/route_option.dart';
import '../../services/polyline_decoder.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/condition_tile.dart';
import '../../widgets/demo_data_badge.dart';
import '../../widgets/route_step_item.dart';

class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({super.key, required this.route});

  final GoogleRoute route;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final routePoints = PolylineDecoder.decode(widget.route.encodedPolyline);

    final routePolyline = Polyline(
      polylineId: const PolylineId('selected_route'),
      points: routePoints,
      color: Colors.blue,
      width: 5,
    );

    final routeMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: routePoints.first,
        infoWindow: const InfoWindow(title: 'Starting Point'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: routePoints.last,
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    };

    final routeSteps = widget.route.journeySegments.asMap().entries.map((
      entry,
    ) {
      final segment = entry.value;

      if (segment.isTransit && segment.transitSegment != null) {
        final transit = segment.transitSegment!;

        final line = transit.lineShortName ?? transit.lineName;

        final direction = transit.headsign ?? '';

        final stops = transit.stopCount;

        return RouteStep(
          n: entry.key + 1,
          text: 'BUS $line → $direction',
          detail:
              '${transit.departureStop?.name ?? 'Unknown stop'}'
              ' → '
              '${transit.arrivalStop?.name ?? 'Unknown stop'}'
              ' • $stops stops',
        );
      }

      return RouteStep(
        n: entry.key + 1,
        text: segment.instruction,
        detail: 'Walking',
      );
    }).toList();

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
                polylines: {routePolyline},
                markers: routeMarkers,
                onMapCreated: (controller) {
                  if (routePoints.isEmpty) {
                    return;
                  }

                  final bounds = _getRouteBounds(routePoints);

                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 60),
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

                  if (routeSteps.isEmpty)
                    const Text('No step-by-step instructions available.')
                  else ...[
                    const DemoDataBadge(),

                    for (var i = 0; i < routeSteps.length; i++)
                      RouteStepItem(
                        step: routeSteps[i],
                        isLast: i == routeSteps.length - 1,
                      ),
                  ],

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
