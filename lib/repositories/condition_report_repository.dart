import '../models/condition_report.dart';

/// Abstract contract for persisting and retrieving condition reports.
///
/// [ConditionReportService] talks to this interface, never to a concrete
/// implementation, so the backend can be swapped without touching any
/// screen, widget, or provider:
///
/// - [LocalConditionReportRepository] — on-device storage.
/// - [RemoteConditionReportRepository] — generic REST API.
/// - [FirebaseConditionReportRepository] — Firestore + Firebase Storage
///   (this is what's wired up in `main.dart` now).
///
/// Whichever implementation is active, [updateReportStatus] is the
/// single entry point admin verification flows use to move a report
/// between [ReportStatus.underReview] and [ReportStatus.verified], so
/// that logic doesn't need to change per backend either.
abstract class ConditionReportRepository {
  /// Creates a new report and returns it with any server-assigned
  /// fields filled in (e.g. the generated document ID, uploaded photo
  /// URL, and server timestamp).
  Future<ConditionReport> createReport(ConditionReport report);

  /// Returns all reports submitted by [userId], most recent first.
  Future<List<ConditionReport>> getUserReports(String userId);

  /// Applies a status change (typically an admin review decision) to an
  /// existing report and returns the updated report.
  Future<ConditionReport> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminComment,
  });

  /// Removes a report (e.g. user retracts a mistaken report).
  Future<void> deleteReport(String reportId);
}
