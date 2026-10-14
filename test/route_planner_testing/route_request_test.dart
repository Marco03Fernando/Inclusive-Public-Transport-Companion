import 'package:flutter_test/flutter_test.dart';
import 'package:colombo_pal/models/route_request.dart';

void main() {
  group('RouteRequest', () {
    test('uses the default preferences', () {
      const request = RouteRequest(
        origin: 'Kaduwela',
        destination: 'Pettah',
      );

      expect(request.origin, 'Kaduwela');
      expect(request.destination, 'Pettah');
      expect(
        request.transitPreference,
        TransitPreference.fewerTransfers,
      );
      expect(request.computeAlternativeRoutes, isTrue);
    });

    test('supports the less-walking preference', () {
      const request = RouteRequest(
        origin: 'Kaduwela',
        destination: 'Pettah',
        transitPreference: TransitPreference.lessWalking,
        computeAlternativeRoutes: false,
      );

      expect(
        request.transitPreference,
        TransitPreference.lessWalking,
      );
      expect(request.computeAlternativeRoutes, isFalse);
    });

    test('preserves the supplied locations', () {
      const request = RouteRequest(
        origin: 'Colombo Fort',
        destination: 'Malabe',
      );

      expect(request.origin, 'Colombo Fort');
      expect(request.destination, 'Malabe');
    });
  });
}