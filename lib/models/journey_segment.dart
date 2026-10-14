import 'transit_segment.dart';

class JourneySegment {
  const JourneySegment({
    required this.travelMode,
    required this.instruction,
    this.distanceMeters = 0,
    this.duration = Duration.zero,
    this.transitSegment,
  });

  final String travelMode;
  final String instruction;
  final int distanceMeters;
  final Duration duration;
  final TransitSegment? transitSegment;

  bool get isWalking => travelMode == 'WALK';

  bool get isTransit => travelMode == 'TRANSIT';
}