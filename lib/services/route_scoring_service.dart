
import '../models/condition_report.dart';
import '../models/google_route.dart';
import '../models/report_model.dart';
import '../repositories/condition_report_repository.dart';

class RouteScoringService {
  final ConditionReportRepository repository;

  RouteScoringService({required this.repository});

  Future<List<GoogleRoute>> rankRoutes(List<GoogleRoute> routes) async {
    if (routes.isEmpty) return [];

    final reports = await repository.getRouteEligibleReports();

    final conditionScores = <String, int>{};
    final goodCounts = <String, int>{};
    final badCounts = <String, int>{};

    // Calculate the score and report counts for each bus route.
    for (final report in reports) {
      final routeId = BusRoute.normalize(report.routeId);

      if (report.reportType == ReportType.positive) {
        conditionScores.update(
          routeId,
          (score) => score + 1,
          ifAbsent: () => 1,
        );
        goodCounts.update(
          routeId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      } else if (report.reportType == ReportType.issue) {
        conditionScores.update(
          routeId,
          (score) => score - 1,
          ifAbsent: () => -1,
        );
        badCounts.update(
          routeId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    // Attach the report scores and counts to each journey.
    final routesWithReports = routes.map((route) {
      var conditionScore = 0;
      var goodCount = 0;
      var badCount = 0;

      for (final segment in route.transitSegments) {
        final routeNumber = segment.lineShortName ?? segment.lineName;
        final routeId = BusRoute.normalize(routeNumber);

        conditionScore += conditionScores[routeId] ?? 0;
        goodCount += goodCounts[routeId] ?? 0;
        badCount += badCounts[routeId] ?? 0;
      }

      return route.copyWith(
        conditionScore: conditionScore,
        goodReportCount: goodCount,
        badReportCount: badCount,
      );
    }).toList();

    // Find the minimum and maximum values for normalizing each factor.
    final durations = routesWithReports
        .map((route) => route.duration.inSeconds.toDouble())
        .toList();
    final distances = routesWithReports
        .map((route) => route.distanceMeters.toDouble())
        .toList();
    final transfers = routesWithReports
        .map((route) => route.transferCount.toDouble())
        .toList();

    final maxAbsCondition = routesWithReports
        .map((route) => route.conditionScore.abs())
        .fold<int>(0, (maxValue, score) =>
            score > maxValue ? score : maxValue);

    double normalizeLowerIsBetter(double value, List<double> values) {
      final minValue = values.reduce((a, b) => a < b ? a : b);
      final maxValue = values.reduce((a, b) => a > b ? a : b);

      if (maxValue == minValue) return 100;

      return ((maxValue - value) / (maxValue - minValue)) * 100;
    }

    // Combine the four factors into one recommendation score.
    final rankedRoutes = routesWithReports.map((route) {
      final timeScore = normalizeLowerIsBetter(
        route.duration.inSeconds.toDouble(),
        durations,
      );

      final transferScore = normalizeLowerIsBetter(
        route.transferCount.toDouble(),
        transfers,
      );

      final distanceScore = normalizeLowerIsBetter(
        route.distanceMeters.toDouble(),
        distances,
      );

      // No reports means neutral (50), not bad.
      // Positive evidence raises this factor; negative evidence lowers it.
      final conditionFactor = maxAbsCondition == 0
          ? 50.0
          : 50.0 +
              (50.0 * route.conditionScore / maxAbsCondition)
                  .clamp(-50.0, 50.0);

      final recommendationScore =
          (timeScore * 0.50) +
          (transferScore * 0.25) +
          (conditionFactor * 0.15) +
          (distanceScore * 0.10);

      return route.copyWith(
        recommendationScore: recommendationScore,
      );
    }).toList();

    // Highest combined score first.
    rankedRoutes.sort(
      (a, b) =>
          b.recommendationScore.compareTo(a.recommendationScore),
    );

    return rankedRoutes;
  }
}
