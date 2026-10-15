import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/google_route.dart';
import '../../models/route_option.dart';
import '../../services/polyline_decoder.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/route_step_item.dart';
import '../../models/condition_report.dart';
import '../../repositories/firebase_condition_report_repository.dart';

class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({super.key, required this.route});

  final GoogleRoute route;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late final Future<List<ConditionReport>> _reportsFuture =
      FirebaseConditionReportRepository().getRouteEligibleReports().then((
        reports,
      ) {
        final routeIds = widget.route.transitSegments
            .map(
              (segment) =>
                  BusRoute.normalize(segment.lineShortName ?? segment.lineName),
            )
            .toSet();

        return reports
            .where((report) => routeIds.contains(report.routeId))
            .toList();
      });

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
      title: widget.route.routeName,
      scrollableBody: false,

      onBack: () => Navigator.of(context).pop(),

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

                  FutureBuilder<List<ConditionReport>>(
                    future: _reportsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Text(
                          'Could not load verified reports. Please try again later.',
                        );
                      }

                      final reports = snapshot.data ?? [];

                      if (reports.isEmpty) {
                        return const Text(
                          'No verified condition reports are available for these buses yet.',
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final report in reports) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          report.reportType ==
                                                  ReportType.positive
                                              ? Icons.thumb_up_alt_outlined
                                              : Icons.warning_amber_rounded,
                                          color:
                                              report.reportType ==
                                                  ReportType.positive
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${report.routeLabel} · '
                                            '${report.reportType.label}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(report.conditionType.sentenceCase),
                                    if (report.description
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(report.description),
                                    ],
                                    if (report.location.label
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Location: ${report.location.label}',
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Status: ${report.status.label}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
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
