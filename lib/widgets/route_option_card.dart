import 'package:flutter/material.dart';

import '../models/google_route.dart';
import '../models/transit_segment.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({
    super.key,
    required this.route,
    required this.onTap,
    this.isRecommended = false,
  });

  final GoogleRoute route;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final durationMinutes = route.duration.inMinutes;
    final theme = Theme.of(context);
    final score = route.recommendationScore;
    final scoreText =
        '${score > 0 ? '+' : ''}${score.toStringAsFixed(1)} / 100';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended) ...[
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Recommended route',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Score: $scoreText',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (score > 0)
                    const Icon(Icons.thumb_up_alt_outlined, color: Colors.green)
                  else if (score < 0)
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                ],
              ),

              const SizedBox(height: 16),

              if (route.transitSegments.isNotEmpty)
                ..._buildBusSequence(context)
              else
                const Text('Transit details unavailable'),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              _detailRow(
                Icons.schedule,
                'Journey time',
                '$durationMinutes '
                    '${durationMinutes == 1 ? 'minute' : 'minutes'}',
              ),
              const SizedBox(height: 10),

              _detailRow(
                Icons.straighten,
                'Distance',
                _formatDistance(route.distanceMeters),
              ),
              const SizedBox(height: 10),

              _detailRow(
                Icons.swap_horiz,
                'Transfers',
                '${route.transferCount} '
                    '${route.transferCount == 1 ? 'transfer' : 'transfers'}',
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.thumb_up_alt_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${route.goodReportCount} verified good-condition '
                      '${route.goodReportCount == 1 ? 'report' : 'reports'}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.thumb_down_alt_outlined,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${route.badReportCount} verified bad-condition '
                      '${route.badReportCount == 1 ? 'report' : 'reports'}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

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

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text('$label: $value')),
      ],
    );
  }

  List<Widget> _buildBusSequence(BuildContext context) {
    final widgets = <Widget>[];

    for (var i = 0; i < route.transitSegments.length; i++) {
      final segment = route.transitSegments[i];

      widgets.add(
        Row(
          children: [
            const Icon(Icons.directions_bus, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _segmentText(segment),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (i < route.transitSegments.length - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.only(left: 2, top: 4, bottom: 4),
            child: Icon(Icons.arrow_downward, size: 22),
          ),
        );
      }
    }

    return widgets;
  }

  String _segmentText(TransitSegment segment) {
    final line = segment.lineShortName ?? segment.lineName;
    final vehicle = segment.vehicleType == 'BUS' ? 'Bus' : segment.vehicleType;
    final destination = segment.headsign;

    if (destination != null && destination.trim().isNotEmpty) {
      return '$vehicle $line ($destination)';
    }

    return '$vehicle $line';
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '$meters m';

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
