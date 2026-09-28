import 'transit_stop.dart';

class TransitSegment {
  const TransitSegment({
    required this.vehicleType,
    required this.lineName,
    this.lineShortName,
    this.headsign,
    this.departureStop,
    this.arrivalStop,
    this.stopCount = 0,
  });

  final String vehicleType;
  final String lineName;
  final String? lineShortName;
  final String? headsign;
  final TransitStop? departureStop;
  final TransitStop? arrivalStop;
  final int stopCount;
}