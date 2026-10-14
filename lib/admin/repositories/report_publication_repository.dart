/// Admin control over which accepted reports appear in Community Reports
/// (`public_condition_reports`).
///
/// Kept apart from [AdminReportRepository] so existing implementations of
/// that interface are unaffected. Publication happens automatically when
/// an admin accepts a report whose reporter opted in; these methods let an
/// admin take it down again or put it back.
abstract class ReportPublicationRepository {
  /// Whether the report currently has a public copy.
  Stream<bool> watchPublished(String reportId);

  /// Publishes (re-copies) or removes the public copy of [reportId].
  /// Publishing throws `AdminException` unless the report is accepted and
  /// its reporter opted in to sharing.
  Future<void> setPublished({required String reportId, required bool publish});
}
