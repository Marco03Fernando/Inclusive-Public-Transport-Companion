class TransitStop {
  const TransitStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.departureTime,
    this.arrivalTime,
  });

  final String name;
  final double latitude;
  final double longitude;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
}