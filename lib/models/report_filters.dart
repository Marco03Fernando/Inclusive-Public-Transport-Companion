/// Shared filtering and ordering of condition reports, used by "My
/// Reports", the volunteer dashboard counts, and the admin report list —
/// so every screen classifies a report the same way.
///
/// Everything here works on an already-authorised list in memory (a
/// user's own reports, or an admin's full list); nothing changes or
/// re-reads Firestore documents.
library;

import 'condition_report.dart';

/// Review-state helpers on the existing [ReportStatus] values. No new
/// statuses: `verified` is the legacy name for `accepted`.
extension ReportStatusReview on ReportStatus {
  /// Waiting for an admin decision. Stored in Firestore as "underReview".
  bool get isPending => this == ReportStatus.underReview;

  /// Approved by an admin. The legacy `verified` value counts as accepted.
  bool get isAccepted =>
      this == ReportStatus.accepted || this == ReportStatus.verified;

  bool get isRejected => this == ReportStatus.rejected;

  /// Default review ordering: approved (0), pending (1), rejected (2).
  int get reviewRank => isAccepted
      ? 0
      : isPending
      ? 1
      : 2;
}

/// Status filter for report lists.
enum StatusFilter {
  all,
  verified,
  underReview,
  rejected;

  bool matches(ConditionReport report) => switch (this) {
    StatusFilter.all => true,
    StatusFilter.verified => report.status.isAccepted,
    StatusFilter.underReview => report.status.isPending,
    StatusFilter.rejected => report.status.isRejected,
  };

  /// English label (admin screens are English-only).
  String get label => switch (this) {
    StatusFilter.all => 'All',
    StatusFilter.verified => 'Verified',
    StatusFilter.underReview => 'Under review',
    StatusFilter.rejected => 'Rejected',
  };

  /// `context.t` key for the user-facing chip.
  String get labelKey => switch (this) {
    StatusFilter.all => 'allFilter',
    StatusFilter.verified => 'filterVerified',
    StatusFilter.underReview => 'filterUnderReview',
    StatusFilter.rejected => 'filterRejected',
  };
}

/// Subject filter, based on [ConditionReport.subject] — never inferred
/// from the route number, since station reports carry a route too.
enum SubjectFilter {
  all,
  bus,
  station,
  restArea,
  other;

  bool matches(ConditionReport report) => matchesSubject(report.subject);

  bool matchesSubject(ReportSubject subject) => switch (this) {
    SubjectFilter.all => true,
    SubjectFilter.bus => subject == ReportSubject.bus,
    SubjectFilter.station => subject == ReportSubject.station,
    SubjectFilter.restArea => subject == ReportSubject.restArea,
    SubjectFilter.other => subject == ReportSubject.other,
  };

  String get label => switch (this) {
    SubjectFilter.all => 'All subjects',
    SubjectFilter.bus => 'Buses',
    SubjectFilter.station => 'Stations',
    SubjectFilter.restArea => 'Rest areas',
    SubjectFilter.other => 'Other',
  };

  /// `context.t` key for the user-facing chip.
  String get labelKey => switch (this) {
    SubjectFilter.all => 'allFilter',
    SubjectFilter.bus => 'busesFilter',
    SubjectFilter.station => 'stationsFilter',
    SubjectFilter.restArea => 'restAreasFilter',
    SubjectFilter.other => 'otherFilter',
  };
}

/// Report type filter (positive feedback / issue / legacy unclassified).
enum TypeFilter {
  all,
  positive,
  issue,
  unclassified;

  bool matches(ConditionReport report) => matchesType(report.reportType);

  bool matchesType(ReportType type) => switch (this) {
    TypeFilter.all => true,
    TypeFilter.positive => type == ReportType.positive,
    TypeFilter.issue => type == ReportType.issue,
    TypeFilter.unclassified => type == ReportType.unknown,
  };

  String get label => switch (this) {
    TypeFilter.all => 'All types',
    TypeFilter.positive => ReportType.positive.label,
    TypeFilter.issue => ReportType.issue.label,
    TypeFilter.unclassified => ReportType.unknown.label,
  };
}

/// List ordering. Ties always fall back to newest first.
enum ReportSort {
  newestFirst,
  oldestFirst,
  verifiedFirst,
  pendingFirst;

  String get label => switch (this) {
    ReportSort.newestFirst => 'Newest first',
    ReportSort.oldestFirst => 'Oldest first',
    ReportSort.verifiedFirst => 'Verified first',
    ReportSort.pendingFirst => 'Pending first',
  };

  int compare(ConditionReport a, ConditionReport b) {
    int newest() => b.createdAt.compareTo(a.createdAt);
    switch (this) {
      case ReportSort.newestFirst:
        return newest();
      case ReportSort.oldestFirst:
        return a.createdAt.compareTo(b.createdAt);
      case ReportSort.verifiedFirst:
        final byRank = a.status.reviewRank.compareTo(b.status.reviewRank);
        return byRank != 0 ? byRank : newest();
      case ReportSort.pendingFirst:
        final byRank = _pendingRank(a.status).compareTo(_pendingRank(b.status));
        return byRank != 0 ? byRank : newest();
    }
  }

  /// Pending (0), approved (1), rejected (2).
  static int _pendingRank(ReportStatus status) => status.isPending
      ? 0
      : status.isAccepted
      ? 1
      : 2;
}

/// A combination of filters plus an ordering, applied together.
class ReportQuery {
  const ReportQuery({
    this.status = StatusFilter.all,
    this.subject = SubjectFilter.all,
    this.type = TypeFilter.all,
    this.sort = ReportSort.verifiedFirst,
  });

  final StatusFilter status;
  final SubjectFilter subject;
  final TypeFilter type;
  final ReportSort sort;

  bool matches(ConditionReport report) =>
      status.matches(report) && subject.matches(report) && type.matches(report);

  /// Filtered and sorted copy of [reports] (input left untouched).
  List<ConditionReport> apply(Iterable<ConditionReport> reports) =>
      reports.where(matches).toList()..sort(sort.compare);

  /// True when any filter (not the ordering) narrows the list.
  bool get isFiltered =>
      status != StatusFilter.all ||
      subject != SubjectFilter.all ||
      type != TypeFilter.all;

  ReportQuery copyWith({
    StatusFilter? status,
    SubjectFilter? subject,
    TypeFilter? type,
    ReportSort? sort,
  }) => ReportQuery(
    status: status ?? this.status,
    subject: subject ?? this.subject,
    type: type ?? this.type,
    sort: sort ?? this.sort,
  );
}
