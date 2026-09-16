import 'transit_segment.dart';

class GoogleRoute {
  const GoogleRoute({
    required this.duration,
    required this.distanceMeters,
    required this.encodedPolyline,
    required this.transitSegments,
  });

  final Duration duration;
  final int distanceMeters;
  final String encodedPolyline;
  final List<TransitSegment> transitSegments;

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
        .map(
          (segment) =>
              segment.lineShortName ?? segment.lineName,
        )
        .join(' + ');
  }
}