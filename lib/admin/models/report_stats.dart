import '../../models/condition_report.dart';
import 'report_filter.dart';

/// Counts shown on the admin dashboard and in the filter tabs.
class ReportStats {
  final int total;
  final int pending;
  final int accepted;
  final int rejected;

  const ReportStats({
    this.total = 0,
    this.pending = 0,
    this.accepted = 0,
    this.rejected = 0,
  });

  factory ReportStats.fromReports(List<ConditionReport> reports) {
    var pending = 0;
    var accepted = 0;
    var rejected = 0;

    for (final report in reports) {
      if (report.status.isPending) {
        pending++;
      } else if (report.status.isAccepted) {
        accepted++;
      } else if (report.status.isRejected) {
        rejected++;
      }
    }

    return ReportStats(
      total: reports.length,
      pending: pending,
      accepted: accepted,
      rejected: rejected,
    );
  }

  int countFor(ReportFilter filter) {
    switch (filter) {
      case ReportFilter.all:
        return total;
      case ReportFilter.underReview:
        return pending;
      case ReportFilter.accepted:
        return accepted;
      case ReportFilter.rejected:
        return rejected;
    }
  }
}
