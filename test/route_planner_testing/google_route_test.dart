import 'package:flutter_test/flutter_test.dart';
import 'package:colombo_pal/models/google_route.dart';
import 'package:colombo_pal/models/transit_segment.dart';

GoogleRoute makeRoute(List<TransitSegment> segments) {
  return GoogleRoute(
    duration: const Duration(minutes: 45),
    distanceMeters: 12000,
    encodedPolyline: '',
    transitSegments: segments,
    instructions: const [],
    journeySegments: const [],
  );
}

TransitSegment bus(String number) {
  return TransitSegment(
    vehicleType: 'BUS',
    lineName: 'Bus $number',
    lineShortName: number,
  );
}

void main() {
  group('GoogleRoute', () {
    test('calculates zero transfers when there are no buses', () {
      expect(makeRoute([]).transferCount, 0);
    });

    test('calculates zero transfers for a direct bus', () {
      final route = makeRoute([bus('143')]);

      expect(route.transferCount, 0);
      expect(route.routeName, '🚍 143');
    });

    test('formats a two-bus route consistently', () {
      final route = makeRoute([bus('177'), bus('174')]);

      expect(route.transferCount, 1);
      expect(route.routeName, '🚍 177 → 🚍 174');
    });

    test('formats routes with three buses', () {
      final route = makeRoute([
        bus('177'),
        bus('174'),
        bus('138'),
      ]);

      expect(route.transferCount, 2);
      expect(route.routeName, '🚍 177 → 🚍 174 → 🚍 138');
    });

    test('uses line name when short name is missing', () {
      final route = makeRoute([
        const TransitSegment(
          vehicleType: 'BUS',
          lineName: 'Kaduwela Bus',
        ),
      ]);

      expect(route.routeName, '🚍 Kaduwela Bus');
    });

    test('uses Transit route when no buses exist', () {
      expect(makeRoute([]).routeName, 'Transit route');
    });

    test('copyWith updates recommendation fields', () {
      final original = makeRoute([bus('143')]);

      final updated = original.copyWith(
        conditionScore: 3,
        goodReportCount: 4,
        badReportCount: 1,
        recommendationScore: 87.5,
      );

      expect(updated.conditionScore, 3);
      expect(updated.goodReportCount, 4);
      expect(updated.badReportCount, 1);
      expect(updated.recommendationScore, 87.5);

      // Original route should remain unchanged.
      expect(original.conditionScore, 0);
      expect(original.recommendationScore, 0);
    });
  });
}