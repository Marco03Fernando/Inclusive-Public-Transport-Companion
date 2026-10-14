import '../../models/condition_report.dart';
import '../../models/report_filters.dart';

// isPending / isAccepted / isRejected now live in the shared
// `models/report_filters.dart`, re-exported so existing admin imports
// keep working.
export '../../models/report_filters.dart' show ReportStatusReview;

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
        return 'Verified / Accepted';
      case ReportFilter.rejected:
        return 'Rejected';
    }
  }

  /// The equivalent shared [StatusFilter] — one definition of what each
  /// status group contains, for admin and user screens alike.
  StatusFilter get statusFilter => switch (this) {
    ReportFilter.all => StatusFilter.all,
    ReportFilter.underReview => StatusFilter.underReview,
    ReportFilter.accepted => StatusFilter.verified,
    ReportFilter.rejected => StatusFilter.rejected,
  };

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

  bool matches(ConditionReport report) => statusFilter.matches(report);
}
