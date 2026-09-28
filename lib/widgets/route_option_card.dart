import 'package:flutter/material.dart';

import '../models/google_route.dart';
import '../models/transit_segment.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({
    super.key,
    required this.route,
    required this.onTap,
  });

  final GoogleRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final durationMinutes = route.duration.inMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------
              // BUS JOURNEY
              // ----------------------------------------------------------
              if (route.transitSegments.isNotEmpty)
                ..._buildBusSequence(context),

              const SizedBox(height: 18),

              // ----------------------------------------------------------
              // DIVIDER
              // ----------------------------------------------------------
              const Divider(),

              const SizedBox(height: 14),

              // ----------------------------------------------------------
              // JOURNEY TIME
              // ----------------------------------------------------------
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duration : $durationMinutes '
                    '${durationMinutes == 1 ? 'minute' : 'minutes'}',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ----------------------------------------------------------
              // DISTANCE
              // ----------------------------------------------------------
              Row(
                children: [
                  const Icon(
                    Icons.straighten,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Distance : ${_formatDistance(route.distanceMeters)}',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ----------------------------------------------------------
              // TRANSFERS
              // ----------------------------------------------------------
              Row(
                children: [
                  const Icon(
                    Icons.swap_horiz,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Transfers: ${route.transferCount} '
                    '${route.transferCount == 1 ? 'transfer' : 'transfers'}',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------
              // COMPACT BUS SEQUENCE
              // ----------------------------------------------------------
              if (route.transitSegments.isNotEmpty)
                _buildCompactBusSequence(),

              const SizedBox(height: 14),

              // ----------------------------------------------------------
              // VIEW ROUTE
              // ----------------------------------------------------------
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onTap,
                  child: const Text('View route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBusSequence(BuildContext context) {
    final widgets = <Widget>[];

    for (var i = 0; i < route.transitSegments.length; i++) {
      final segment = route.transitSegments[i];

      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _segmentText(segment),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      // Down arrow between buses
      if (i < route.transitSegments.length - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.only(
              left: 2,
              top: 4,
              bottom: 4,
            ),
            child: Icon(
              Icons.arrow_downward,
              size: 22,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildCompactBusSequence() {
    final widgets = <Widget>[];

    for (var i = 0; i < route.transitSegments.length; i++) {
      final segment = route.transitSegments[i];

      if (i > 0) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward,
              size: 20,
            ),
          ),
        );
      }

      widgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              segment.lineShortName ?? segment.lineName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: widgets,
    );
  }

  String _segmentText(TransitSegment segment) {
    final line =
        segment.lineShortName ?? segment.lineName;

    final vehicle = segment.vehicleType == 'BUS'
        ? 'Bus'
        : segment.vehicleType;

    final destination = segment.headsign;

    if (destination != null &&
        destination.trim().isNotEmpty) {
      return '$vehicle $line ($destination)';
    }

    return '$vehicle $line';
  }

  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }

    final kilometers = meters / 1000;

    return '${kilometers.toStringAsFixed(1)} km';
  }
}
