import '../models/condition_report.dart';

/// Abstract contract for persisting and retrieving condition reports.
///
/// [ConditionReportService] talks to this interface, never to a concrete
/// implementation, so the backend can be swapped without touching any
/// screen, widget, or provider:
///
/// - [LocalConditionReportRepository] — on-device storage (wired up now).
/// - [RemoteConditionReportRepository] — REST API (stubbed, ready to point
///   at a real base URL).
/// - A Firestore-backed repository can be added the same way: implement
///   this interface, mapping each method onto `collection('reports')`
///   reads/writes and returning/accepting [ConditionReport] via
///   [ConditionReport.toJson] / [ConditionReport.fromJson].
///
/// Whichever implementation is active, [updateStatus] is the single entry
/// point admin verification flows use to move a report from
/// `ReportStatus.underReview` to `ReportStatus.verified` (or back), so
/// that logic also doesn't need to change per backend.
abstract class ConditionReportRepository {
  /// Returns all reports, most recent first.
  Future<List<ConditionReport>> fetchAll();

  /// Persists a new report and returns it (with any server-assigned
  /// fields filled in, once there is a server).
  Future<ConditionReport> create(ConditionReport report);

  /// Applies an admin review decision to an existing report.
  Future<ConditionReport> updateStatus({
    required String reportId,
    required ReportStatus status,
    AdminVerification? adminVerification,
  });

  /// Removes a report (e.g. user retracts a mistaken report).
  Future<void> delete(String reportId);
}
