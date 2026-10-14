// "My Reports" status / subject / type filtering and ordering
// (lib/models/report_filters.dart) — what a reporter sees when tracking
// their reports.
import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/models/condition_report.dart';
import 'package:colombo_pal/models/report_filters.dart';

import 'helpers/test_harness.dart';

void main() {
  final reports = [
    sampleReport(
      id: 'pending-new',
      createdAt: DateTime(2026, 10, 9),
      status: ReportStatus.underReview,
    ),
    sampleReport(
      id: 'accepted-old',
      createdAt: DateTime(2026, 9, 1),
      status: ReportStatus.accepted,
      subject: ReportSubject.station,
      reportType: ReportType.positive,
    ),
    sampleReport(
      id: 'verified-legacy',
      createdAt: DateTime(2026, 9, 15),
      status: ReportStatus.verified,
      subject: ReportSubject.restArea,
    ),
    sampleReport(
      id: 'rejected',
      createdAt: DateTime(2026, 10, 2),
      status: ReportStatus.rejected,
    ),
  ];

  List<String> ids(Iterable<ConditionReport> list) =>
      list.map((r) => r.id).toList();

  test('legacy "verified" counts as accepted everywhere', () {
    expect(ReportStatus.verified.isAccepted, isTrue);
    expect(StatusFilter.verified.matches(reports[2]), isTrue);
  });

  test('default ordering: approved, then pending, then rejected', () {
    final sorted = const ReportQuery().apply(reports);
    expect(ids(sorted), [
      'verified-legacy',
      'accepted-old',
      'pending-new',
      'rejected',
    ]);
  });

  test('pending-first and newest/oldest orderings', () {
    expect(
      ids(const ReportQuery(sort: ReportSort.pendingFirst).apply(reports))
          .first,
      'pending-new',
    );
    expect(
      ids(const ReportQuery(sort: ReportSort.newestFirst).apply(reports)),
      ['pending-new', 'rejected', 'verified-legacy', 'accepted-old'],
    );
    expect(
      ids(const ReportQuery(sort: ReportSort.oldestFirst).apply(reports)).first,
      'accepted-old',
    );
  });

  test('status filters', () {
    expect(
      ids(const ReportQuery(status: StatusFilter.underReview).apply(reports)),
      ['pending-new'],
    );
    expect(
      ids(const ReportQuery(status: StatusFilter.rejected).apply(reports)),
      ['rejected'],
    );
    expect(
      const ReportQuery(status: StatusFilter.verified).apply(reports),
      hasLength(2),
    );
  });

  test('subject and type filters combine with status', () {
    const query = ReportQuery(
      status: StatusFilter.verified,
      subject: SubjectFilter.station,
      type: TypeFilter.positive,
    );
    expect(ids(query.apply(reports)), ['accepted-old']);
    expect(query.isFiltered, isTrue);
    expect(const ReportQuery().isFiltered, isFalse);
  });

  test('a filter that matches nothing returns an empty list', () {
    expect(
      const ReportQuery(subject: SubjectFilter.other).apply(reports),
      isEmpty,
    );
  });

  test('applying a query never mutates the source list', () {
    final before = ids(reports);
    const ReportQuery(sort: ReportSort.oldestFirst).apply(reports);
    expect(ids(reports), before);
  });

  test('type filter keeps legacy unclassified reports reachable', () {
    final legacy = ConditionReport.fromJson(
      sampleReport(id: 'legacy').toJson()..remove('reportType'),
    );
    expect(TypeFilter.unclassified.matches(legacy), isTrue);
    expect(TypeFilter.issue.matches(legacy), isFalse);
  });
}
