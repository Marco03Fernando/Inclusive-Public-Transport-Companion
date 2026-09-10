import '../models/condition_report.dart';
import '../repositories/condition_report_repository.dart';

/// Business-logic layer for condition reports.
///
/// Screens and [ReportsProvider] talk to this service, never directly to
/// a [ConditionReportRepository] implementation. That keeps validation
/// and orchestration in one place regardless of which repository is
/// injected underneath — currently [FirebaseConditionReportRepository]
/// (see `main.dart`), previously local/REST.
class ConditionReportService {
  final ConditionReportRepository _repository;

  ConditionReportService({required ConditionReportRepository repository})
      : _repository = repository;

  /// Submits a new report (uploading its photo first, if any — handled
  /// inside the repository). Every submitted report starts as
  /// [ReportStatus.underReview].
  Future<ConditionReport> createReport(ConditionReport report) async {
    _validate(report);
    return _repository.createReport(report);
  }

  /// Fetches every report [userId] has submitted, most recent first.
  Future<List<ConditionReport>> getUserReports(String userId) {
    return _repository.getUserReports(userId);
  }

  /// Applies an admin's review decision to an existing report.
  ///
  /// Not called from any screen yet — the mobile app only creates and
  /// reads reports. This is here so an admin web panel or a backend
  /// function has a single, already-wired path to flip a report's
  /// status (and leave a comment) once that surface exists.
  Future<ConditionReport> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminComment,
  }) {
    return _repository.updateReportStatus(
      reportId: reportId,
      status: status,
      adminComment: adminComment,
    );
  }

  Future<void> deleteReport(String reportId) => _repository.deleteReport(reportId);

  /// Defensive second check before a report reaches persistence — the UI
  /// (see `utils/validators.dart`) should already prevent invalid
  /// submissions, but the service shouldn't rely solely on that.
  void _validate(ConditionReport report) {
    if (report.description.trim().isEmpty) {
      throw ArgumentError('Report description cannot be empty.');
    }
    if (report.userId.isEmpty) {
      throw ArgumentError('Report must have a userId before it can be submitted.');
    }
  }
}
