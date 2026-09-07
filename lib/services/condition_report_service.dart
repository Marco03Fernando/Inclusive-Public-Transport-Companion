import '../models/condition_report.dart';
import '../repositories/condition_report_repository.dart';

/// Business-logic layer for condition reports.
///
/// Screens and [ReportsProvider] talk to this service, never directly to
/// a [ConditionReportRepository] implementation. That keeps validation,
/// orchestration, and (later) things like retry/caching/analytics in one
/// place regardless of which repository — local, REST, or Firestore — is
/// injected underneath.
class ConditionReportService {
  final ConditionReportRepository _repository;

  ConditionReportService({required ConditionReportRepository repository})
      : _repository = repository;

  Future<List<ConditionReport>> fetchReports() => _repository.fetchAll();

  /// Submits a new report. Every submitted report starts as
  /// [ReportStatus.underReview] — moving to [ReportStatus.verified] is an
  /// admin-only action, see [applyAdminVerification].
  Future<ConditionReport> submitReport(ConditionReport report) async {
    _validate(report);
    return _repository.create(report);
  }

  /// Applies an admin's review decision to an existing report.
  ///
  /// Not called from any screen yet — the mobile app only creates and
  /// reads reports. This is here so an admin web panel or a backend
  /// webhook has a single, already-wired path to flip a report's status
  /// once that surface exists.
  Future<ConditionReport> applyAdminVerification({
    required String reportId,
    required ReportStatus status,
    String? verifiedBy,
    String? notes,
  }) {
    return _repository.updateStatus(
      reportId: reportId,
      status: status,
      adminVerification: AdminVerification(
        verifiedBy: verifiedBy,
        verifiedAt: DateTime.now(),
        notes: notes,
      ),
    );
  }

  Future<void> deleteReport(String reportId) => _repository.delete(reportId);

  /// Defensive second check before a report reaches persistence — the UI
  /// (see `utils/validators.dart`) should already prevent invalid
  /// submissions, but the service shouldn't rely solely on that.
  void _validate(ConditionReport report) {
    if (report.description.trim().isEmpty) {
      throw ArgumentError('Report description cannot be empty.');
    }
  }
}
