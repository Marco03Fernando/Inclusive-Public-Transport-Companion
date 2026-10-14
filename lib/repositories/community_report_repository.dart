import '../models/public_condition_report.dart';

/// Read-only access to the published Community Reports
/// (`public_condition_reports`). Ordinary users never read other people's
/// private `condition_reports`; publishing is an admin action (see
/// `lib/admin/repositories/report_publication_repository.dart`).
abstract class CommunityReportRepository {
  /// Live list of published reports, newest submission first, at most
  /// [limit] long.
  Stream<List<PublicConditionReport>> watchPublishedReports({
    required int limit,
  });

  /// Live copy of one published report; emits null once it is unpublished
  /// or deleted.
  Stream<PublicConditionReport?> watchReport(String reportId);
}
