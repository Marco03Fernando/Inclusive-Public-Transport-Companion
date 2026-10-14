import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/public_condition_report.dart';
import '../models/report_exception.dart';
import '../models/report_filters.dart';
import '../repositories/community_report_repository.dart';

/// State for the Community Reports feed: one live, newest-first query of
/// published reports plus the subject / report-type filters.
///
/// Created with the screen (see `app.dart`), so the Firestore listener
/// only runs while Community Reports is open. Filters apply to the loaded
/// list in memory — changing them costs no reads. Report Details is pushed
/// on top, so the filters survive opening and closing it.
class CommunityReportsProvider extends ChangeNotifier {
  CommunityReportsProvider({required this._repository});

  final CommunityReportRepository _repository;

  static const pageSize = 50;

  StreamSubscription<List<PublicConditionReport>>? _subscription;
  List<PublicConditionReport> _reports = const [];
  int _limit = pageSize;
  bool _hasMore = false;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  SubjectFilter _subject = SubjectFilter.all;
  TypeFilter _type = TypeFilter.all;

  /// Every loaded report, newest first.
  List<PublicConditionReport> get allReports => _reports;

  /// The loaded reports that match both filters.
  List<PublicConditionReport> get reports => _reports
      .where(
        (r) =>
            _subject.matchesSubject(r.subject) &&
            _type.matchesType(r.reportType),
      )
      .toList(growable: false);

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// More (older) published reports exist beyond those loaded.
  bool get hasMore => _hasMore;

  SubjectFilter get subject => _subject;
  TypeFilter get type => _type;
  bool get isFiltered =>
      _subject != SubjectFilter.all || _type != TypeFilter.all;

  void setSubject(SubjectFilter value) {
    if (_subject == value) return;
    _subject = value;
    notifyListeners();
  }

  void setType(TypeFilter value) {
    if (_type == value) return;
    _type = value;
    notifyListeners();
  }

  void clearFilters() {
    _subject = SubjectFilter.all;
    _type = TypeFilter.all;
    notifyListeners();
  }

  /// (Re)subscribes. Completes on the first snapshot or error, so it can
  /// back pull-to-refresh and "Try again".
  Future<void> refresh() => _subscribe();

  /// Extends the live window by one page.
  Future<void> loadMore() {
    if (!_hasMore || _isLoading) return Future.value();
    _limit += pageSize;
    return _subscribe();
  }

  Future<void> _subscribe() {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    _notify();

    final firstEvent = Completer<void>();
    void settle() {
      if (!firstEvent.isCompleted) firstEvent.complete();
    }

    // One extra document tells us whether there is another page.
    _subscription = _repository
        .watchPublishedReports(limit: _limit + 1)
        .listen(
          (reports) {
            _hasMore = reports.length > _limit;
            _reports = _hasMore ? reports.sublist(0, _limit) : reports;
            _isLoading = false;
            _error = null;
            _notify();
            settle();
          },
          onError: (Object e) {
            _isLoading = false;
            _error = e is ReportException
                ? e.message
                : 'Could not load community reports. Please try again.';
            if (kDebugMode) debugPrint('[CommunityReports] $e');
            _notify();
            settle();
          },
        );
    return firstEvent.future;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
