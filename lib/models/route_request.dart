class RouteRequest {
  const RouteRequest({
    required this.origin,
    required this.destination,
    this.transitPreference = TransitPreference.fewerTransfers,
    this.computeAlternativeRoutes = true,
  });

  final String origin;
  final String destination;
  final TransitPreference transitPreference;
  final bool computeAlternativeRoutes;
}

enum TransitPreference {
  fewerTransfers,
  lessWalking,
}