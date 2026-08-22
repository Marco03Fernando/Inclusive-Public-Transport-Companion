enum ReportStatus { verified, underReview }

/// Backs the three near-identical list rows in the design: route
/// conditions on the plan-detail screen, "My Reports", and the volunteer
/// community feed. They differ only in which fields are shown, not shape.
class ConditionReport {
  const ConditionReport({
    required this.title,
    required this.location,
    required this.status,
    this.date,
  });

  final String title;
  final String location;
  final ReportStatus status;
  final String? date;
}
