import '../../models/condition_report.dart';

/// One emission of the live admin report list: the parsed reports plus how
/// many `condition_reports` documents were malformed and had to be skipped.
typedef AdminReportsSnapshot = ({List<ConditionReport> reports, int skipped});

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
  Stream<AdminReportsSnapshot> watchAllReports();

  /// Records an admin decision on a report: `status`, `adminComment` and
  /// `updatedAt` only.
  ///
  /// [decision] must be [ReportStatus.accepted] or [ReportStatus.rejected].
  /// [expectedStatus] is the status the admin was looking at; if the report
  /// changed in the meantime (e.g. another admin reviewed it a moment
  /// earlier) this throws `AdminException` instead of overwriting it.
  Future<void> reviewReport({
    required String reportId,
    required ReportStatus decision,
    required String adminComment,
    required ReportStatus expectedStatus,
  });

  /// Adds or edits the admin comment without changing the status:
  /// `adminComment` and `updatedAt` only.
  Future<void> updateComment({
    required String reportId,
    required String adminComment,
  });

  /// Permanently deletes a report and its uploaded photo (if any).
  Future<void> deleteReport(String reportId);
}
