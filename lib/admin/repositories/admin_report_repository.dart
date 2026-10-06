import '../../models/condition_report.dart';

/// Contract for the admin side of condition reports.
///
/// This is deliberately a SEPARATE interface from the user-side
/// `ConditionReportRepository`: that one is implemented by the local and
/// REST repositories too, so adding admin methods to it would force
/// changes to files that have nothing to do with admins. The admin module
/// only ever talks to Firestore, and both sides share the same
/// `condition_reports` collection.
abstract class AdminReportRepository {
  /// Live stream of EVERY report, newest first. Emits again whenever any
  /// report changes, so the dashboard counts and the list stay current
  /// without manual refreshing.
  Stream<List<ConditionReport>> watchAllReports();

  /// Records an admin decision on a report.
  ///
  /// [decision] must be [ReportStatus.accepted] or [ReportStatus.rejected].
  /// Throws `AdminException` if the report no longer exists or was already
  /// reviewed (e.g. by another admin a moment earlier).
  Future<void> reviewReport({
    required String reportId,
    required ReportStatus decision,
    required String adminComment,
  });

  /// Permanently deletes a report and its uploaded photo (if any).
  Future<void> deleteReport(String reportId);
}
