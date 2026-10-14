import 'transit_segment.dart';
import 'route_instruction.dart';
import 'journey_segment.dart';

class GoogleRoute {
  const GoogleRoute({
    required this.duration,
    required this.distanceMeters,
    required this.encodedPolyline,
    required this.transitSegments,
    required this.instructions,
    required this.journeySegments,
  });

  final Duration duration;
  final int distanceMeters;
  final String encodedPolyline;
  final List<TransitSegment> transitSegments;
  final List<RouteInstruction> instructions;
  final List<JourneySegment> journeySegments;

  int get transferCount {
    if (transitSegments.isEmpty) {
      return 0;
    }

    return transitSegments.length - 1;
  }

  String get routeName {
    if (transitSegments.isEmpty) {
      return 'Transit route';
    }

    return transitSegments
        .map((segment) => segment.lineShortName ?? segment.lineName)
        .join(' + ');
  }
}
