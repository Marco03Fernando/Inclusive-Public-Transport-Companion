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
    this.conditionScore = 0,
    this.goodReportCount = 0,
    this.badReportCount = 0,
    this.recommendationScore = 0,
  });

  final Duration duration;
  final int distanceMeters;
  final String encodedPolyline;
  final List<TransitSegment> transitSegments;
  final List<RouteInstruction> instructions;
  final List<JourneySegment> journeySegments;

  /// Net score from accepted/verified condition reports.
  final int conditionScore;

  /// Number of eligible positive reports for buses on this route.
  final int goodReportCount;

  /// Number of eligible accessibility issue reports for buses on this route.
  final int badReportCount;

  /// Combined score used to rank route recommendations.
  final double recommendationScore;

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
      .map((segment) => '🚍 ${segment.lineShortName ?? segment.lineName}')
      .join(' → ');
}


  GoogleRoute copyWith({
    int? conditionScore,
    int? goodReportCount,
    int? badReportCount,
    double? recommendationScore,
  }) {
    return GoogleRoute(
      duration: duration,
      distanceMeters: distanceMeters,
      encodedPolyline: encodedPolyline,
      transitSegments: transitSegments,
      instructions: instructions,
      journeySegments: journeySegments,
      conditionScore: conditionScore ?? this.conditionScore,
      goodReportCount: goodReportCount ?? this.goodReportCount,
      badReportCount: badReportCount ?? this.badReportCount,
      recommendationScore: recommendationScore ?? this.recommendationScore,
    );
  }
}
