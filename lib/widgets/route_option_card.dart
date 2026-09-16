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
              Row(
                children: [
                  const Icon(Icons.directions_bus),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      route.routeName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 6),
                  Text('$durationMinutes min'),

                  const SizedBox(width: 20),

                  const Icon(Icons.straighten, size: 18),
                  const SizedBox(width: 6),
                  Text(_formatDistance(route.distanceMeters)),

                  const SizedBox(width: 20),

                  const Icon(Icons.swap_horiz, size: 18),
                  const SizedBox(width: 6),
                  Text('${route.transferCount} transfers'),
                ],
              ),

              if (route.transitSegments.isNotEmpty) ...[
                const SizedBox(height: 14),

                ...route.transitSegments.map(
                  (segment) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_transit,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _segmentText(segment),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

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

  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }

    final kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  }

  String _segmentText(TransitSegment segment) {
    final line =
        segment.lineShortName ?? segment.lineName;

    final vehicle = segment.vehicleType == 'BUS'
        ? 'Bus'
        : segment.vehicleType;

    return '$vehicle $line';
  }
}