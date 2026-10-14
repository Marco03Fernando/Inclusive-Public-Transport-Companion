import '../../models/condition_report.dart';

/// Admin-side helpers on the shared [ReportStatus] enum.
///
/// Kept here (not in `models/report_model.dart`) so the user-side model
/// stays free of admin concepts.
extension ReportStatusAdmin on ReportStatus {
  /// Waiting for an admin decision. Stored in Firestore as "underReview".
  bool get isPending => this == ReportStatus.underReview;

  /// Accepted. The legacy `verified` value counts as accepted.
  bool get isAccepted =>
      this == ReportStatus.accepted || this == ReportStatus.verified;

  bool get isRejected => this == ReportStatus.rejected;
}

/// Reads a stored `status` value. Documents store `status.name`
/// ("underReview"); "under_review" is also accepted in case a document was
/// edited by hand. Anything unknown counts as still waiting for review, so
/// it stays visible to the admin instead of vanishing.
ReportStatus parseReportStatus(Object? raw) {
  switch (raw) {
    case 'accepted':
      return ReportStatus.accepted;
    case 'rejected':
      return ReportStatus.rejected;
    case 'verified':
      return ReportStatus.verified;
    default:
      return ReportStatus.underReview;
  }
}

/// The status tabs on the report management screen.
enum ReportFilter { all, underReview, accepted, rejected }

extension ReportFilterX on ReportFilter {
  String get label {
    switch (this) {
      case ReportFilter.all:
        return 'All';
      case ReportFilter.underReview:
        return 'Under review';
      case ReportFilter.accepted:
        return 'Accepted';
      case ReportFilter.rejected:
        return 'Rejected';
    }
  }

  /// Text for the "nothing here" state when this filter has no reports.
  String get emptyMessage {
    switch (this) {
      case ReportFilter.all:
        return 'No reports have been submitted yet.';
      case ReportFilter.underReview:
        return 'No reports are waiting for review.';
      case ReportFilter.accepted:
        return 'No reports have been accepted yet.';
      case ReportFilter.rejected:
        return 'No reports have been rejected yet.';
    }
  }

  bool matches(ConditionReport report) {
    switch (this) {
      case ReportFilter.all:
        return true;
      case ReportFilter.underReview:
        return report.status.isPending;
      case ReportFilter.accepted:
        return report.status.isAccepted;
      case ReportFilter.rejected:
        return report.status.isRejected;
    }
  }
}
