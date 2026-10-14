import '../../models/condition_report.dart';
import '../models/admin_exception.dart';
import '../repositories/admin_report_repository.dart';
import '../repositories/report_publication_repository.dart';

/// Business-logic layer for the admin review workflow.
///
/// The provider talks to this service, never to the repository directly —
/// the same layering as `ConditionReportService` on the user side.
class AdminReportService {
  /// Written to `adminComment` when an admin accepts without typing a note,
  /// so an accepted report always has a comment.
  static const String defaultAcceptComment = 'Report accepted.';

  static const int maxCommentLength = 300;

  final AdminReportRepository _repository;

  /// Community Reports publication controls; null where not wired up.
  final ReportPublicationRepository? _publication;

  AdminReportService({required this._repository, this._publication});

  /// Whether [reportId] is currently shown in Community Reports.
  Stream<bool> watchPublished(String reportId) =>
      _publication?.watchPublished(reportId) ?? Stream.value(false);

  /// Shows (re-publishes) or hides [reportId] in Community Reports.
  Future<void> setPublished({required String reportId, required bool publish}) {
    final publication = _publication;
    if (publication == null) {
      throw const AdminException('Community publishing is not available.');
    }
    return publication.setPublished(reportId: reportId, publish: publish);
  }

  Stream<AdminReportsSnapshot> watchAllReports() =>
      _repository.watchAllReports();

  /// status = accepted, adminComment = [comment] (or a default),
  /// updatedAt = server time.
  Future<void> acceptReport({
    required String reportId,
    required ReportStatus currentStatus,
    String? comment,
  }) async {
    final trimmed = _checkLength(comment?.trim() ?? '');

    await _repository.reviewReport(
      reportId: reportId,
      decision: ReportStatus.accepted,
      adminComment: trimmed.isEmpty ? defaultAcceptComment : trimmed,
      expectedStatus: currentStatus,
    );
  }

  /// status = rejected, adminComment = [reason], updatedAt = server time.
  /// A reason is mandatory.
  Future<void> rejectReport({
    required String reportId,
    required ReportStatus currentStatus,
    required String reason,
  }) async {
    final trimmed = _checkLength(reason.trim());

    if (trimmed.isEmpty) {
      throw const AdminException(
        'Please enter a reason for rejecting this report.',
      );
    }

    await _repository.reviewReport(
      reportId: reportId,
      decision: ReportStatus.rejected,
      adminComment: trimmed,
      expectedStatus: currentStatus,
    );
  }

  /// adminComment = [comment], updatedAt = server time. Status unchanged.
  Future<void> updateComment({
    required String reportId,
    required String comment,
  }) async {
    final trimmed = _checkLength(comment.trim());
    if (trimmed.isEmpty) {
      throw const AdminException('Please enter a comment.');
    }
    await _repository.updateComment(reportId: reportId, adminComment: trimmed);
  }

  /// Permanently removes the report document and its photo.
  Future<void> deleteReport(String reportId) =>
      _repository.deleteReport(reportId);

  String _checkLength(String value) {
    if (value.length > maxCommentLength) {
      throw const AdminException(
        'Comments can be at most $maxCommentLength characters.',
      );
    }
    return value;
  }
}
