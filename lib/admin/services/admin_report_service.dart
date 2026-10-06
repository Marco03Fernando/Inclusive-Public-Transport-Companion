import '../../models/condition_report.dart';
import '../models/admin_exception.dart';
import '../repositories/admin_report_repository.dart';

/// Business-logic layer for the admin review workflow.
///
/// The provider talks to this service, never to the repository directly —
/// the same layering as `ConditionReportService` on the user side.
class AdminReportService {
  /// Written to `adminComment` when an admin accepts without typing a note,
  /// so an accepted report always has a comment (as the spec requires).
  static const String defaultAcceptComment = 'Report accepted.';

  final AdminReportRepository _repository;

  AdminReportService({required AdminReportRepository repository})
      : _repository = repository;

  Stream<List<ConditionReport>> watchAllReports() =>
      _repository.watchAllReports();

  /// status = accepted, adminComment = [comment] (or a default),
  /// updatedAt = server time.
  Future<void> acceptReport({
    required String reportId,
    String? comment,
  }) async {
    final trimmed = comment?.trim() ?? '';

    await _repository.reviewReport(
      reportId: reportId,
      decision: ReportStatus.accepted,
      adminComment: trimmed.isEmpty ? defaultAcceptComment : trimmed,
    );
  }

  /// status = rejected, adminComment = [reason], updatedAt = server time.
  /// A reason is mandatory.
  Future<void> rejectReport({
    required String reportId,
    required String reason,
  }) async {
    final trimmed = reason.trim();

    if (trimmed.isEmpty) {
      throw const AdminException(
        'Please enter a reason for rejecting this report.',
      );
    }

    await _repository.reviewReport(
      reportId: reportId,
      decision: ReportStatus.rejected,
      adminComment: trimmed,
    );
  }

  /// Permanently removes the report document and its photo.
  Future<void> deleteReport(String reportId) =>
      _repository.deleteReport(reportId);
}
