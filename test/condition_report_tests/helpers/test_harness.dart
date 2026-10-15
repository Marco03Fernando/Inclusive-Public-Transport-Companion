// Shared fakes and pump helpers for the Condition Reporting tests.
//
// Nothing here touches Firebase: auth, profiles, the report repository,
// GPS and the image picker are all in-memory fakes, so no test can write
// to the real project.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colombo_pal/core/localization/locale.dart';
import 'package:colombo_pal/core/routes.dart';
import 'package:colombo_pal/core/state/accessibility_settings.dart';
import 'package:colombo_pal/core/state/app_state.dart';
import 'package:colombo_pal/core/state/auth_state.dart';
import 'package:colombo_pal/core/theme/app_theme.dart';
import 'package:colombo_pal/models/condition_report.dart';
import 'package:colombo_pal/models/user_profile.dart';
import 'package:colombo_pal/providers/reports_provider.dart';
import 'package:colombo_pal/repositories/condition_report_repository.dart';
import 'package:colombo_pal/services/auth_service.dart';
import 'package:colombo_pal/services/condition_report_service.dart';
import 'package:colombo_pal/services/location_service.dart';
import 'package:colombo_pal/services/photo_service.dart';
import 'package:colombo_pal/services/read_aloud_service.dart';
import 'package:colombo_pal/services/user_profile_service.dart';

/// Signed-in user (or nobody, when [uid] is null). Only the members the
/// reporting flow uses are implemented.
class FakeAuthService implements AuthService {
  FakeAuthService({this.uid = 'user-a'});

  String? uid;

  @override
  String? get currentUserId => uid;

  @override
  User? get currentUser => null;

  @override
  Future<String> ensureSignedIn() async {
    final id = uid;
    if (id == null) {
      throw AuthServiceException('Please sign in again to continue.');
    }
    return id;
  }

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Profiles are never read in these tests; constructing the real service
/// would require Firebase.
class FakeUserProfileService implements UserProfileService {
  @override
  Stream<UserProfile?> watchProfile(String uid) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// In-memory [ConditionReportRepository] that records every call, keeps
/// reports per user, pushes live updates and can be told to fail.
class FakeReportRepository implements ConditionReportRepository {
  final List<ConditionReport> stored = [];
  final List<ConditionReport> createCalls = [];
  final List<String> watchedUserIds = [];
  final _controllers = <String, StreamController<List<ConditionReport>>>{};

  /// Thrown by the next [createReport] call(s) while set.
  Object? createError;

  /// Thrown (as a stream error) by [watchUserReports] while set.
  Object? watchError;

  int _nextId = 1;

  List<ConditionReport> _forUser(String userId) =>
      stored.where((r) => r.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void _emit(String userId) => _controllers[userId]?.add(_forUser(userId));

  /// Seeds a report as if it already existed in Firestore.
  void seed(ConditionReport report) {
    stored.add(report);
    _emit(report.userId);
  }

  /// Route scoring isn't exercised by these tests.
  @override
  Future<List<ConditionReport>> getRouteEligibleReports() async => const [];

  @override
  Future<ConditionReport> createReport(ConditionReport report) async {
    createCalls.add(report);
    final error = createError;
    if (error != null) throw error;
    final saved = report.copyWith(
      id: 'report-${_nextId++}',
      photoUrl: report.photoPath == null
          ? null
          : 'https://example.test/${report.userId}.jpg',
    );
    stored.add(saved);
    _emit(saved.userId);
    return saved;
  }

  @override
  Future<List<ConditionReport>> getUserReports(String userId) async =>
      _forUser(userId);

  @override
  Stream<List<ConditionReport>> watchUserReports(String userId) {
    watchedUserIds.add(userId);
    final error = watchError;
    if (error != null) return Stream.error(error);
    final controller = _controllers.putIfAbsent(
      userId,
      () => StreamController<List<ConditionReport>>.broadcast(),
    );
    scheduleMicrotask(() => _emit(userId));
    return controller.stream;
  }

  @override
  Future<ConditionReport> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminComment,
  }) async {
    final index = stored.indexWhere((r) => r.id == reportId);
    final updated = stored[index].copyWith(
      status: status,
      adminComment: adminComment,
    );
    stored[index] = updated;
    _emit(updated.userId);
    return updated;
  }

  @override
  Future<void> deleteReport(String reportId) async {
    final report = stored.firstWhere((r) => r.id == reportId);
    stored.remove(report);
    _emit(report.userId);
  }

  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.close();
    }
  }
}

/// GPS stand-in: returns [location] or throws [error].
class FakeLocationService extends LocationService {
  FakeLocationService({this.location, this.error});

  ReportLocation? location;
  LocationServiceException? error;
  int calls = 0;

  @override
  Future<ReportLocation> getCurrentLocation() async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return location ??
        const ReportLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          label: 'Current location attached',
        );
  }
}

/// Camera/gallery stand-in: returns [path] (null = user cancelled) or
/// throws [error]. Records which source was requested.
class FakePhotoService extends PhotoService {
  FakePhotoService({this.path, this.error});

  String? path;
  PhotoServiceException? error;
  final List<PhotoSource> requests = [];

  @override
  Future<String?> pickPhoto(PhotoSource source) async {
    requests.add(source);
    final e = error;
    if (e != null) throw e;
    return path;
  }
}

/// A complete, valid report owned by [userId].
ConditionReport sampleReport({
  String id = 'r1',
  String userId = 'user-a',
  ReportStatus status = ReportStatus.underReview,
  ReportSubject subject = ReportSubject.bus,
  ReportType reportType = ReportType.issue,
  DateTime? createdAt,
  String routeNumber = '138A',
}) {
  return ConditionReport(
    id: id,
    userId: userId,
    reportType: reportType,
    routeNumber: routeNumber,
    routeId: BusRoute.normalize(routeNumber),
    subject: subject,
    vehicleOrStationNumber: 'NB-1234',
    location: const ReportLocation(label: 'Fort'),
    conditionType: ConditionType.brokenRamp,
    description: 'Ramp is bent and will not lower.',
    createdAt: createdAt ?? DateTime(2026, 10, 1, 9, 20),
    status: status,
  );
}

bool _isFontLoadError(Object error) {
  final text = '$error';
  return text.contains('google_fonts') ||
      text.contains('Failed to load font') ||
      text.contains('allowRuntimeFetching');
}

/// `testWidgets` for screens that use Google Fonts. The fonts are fetched
/// at runtime in the app (they are not bundled), which always fails in the
/// offline test environment; those font-load errors — and only those — are
/// ignored. Every other error still fails the test.
void reportWidgetTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    final done = Completer<void>();
    runZonedGuarded(
      () async {
        await body(tester);
        if (!done.isCompleted) done.complete();
      },
      (error, stack) {
        if (_isFontLoadError(error)) return;
        if (!done.isCompleted) done.completeError(error, stack);
      },
    );
    await done.future;
  });
}

/// Everything the report screens read from the provider tree.
class ReportTestApp {
  ReportTestApp({FakeAuthService? auth, FakeReportRepository? repository})
    : auth = auth ?? FakeAuthService(),
      repository = repository ?? FakeReportRepository();

  final FakeAuthService auth;
  final FakeReportRepository repository;
  late final ReportsProvider reports;

  /// Wraps [home] in the same providers / theme / strings as `app.dart`.
  /// [routes] are extra named routes (e.g. the confirmation screen).
  Widget build(
    Widget home, {
    AppLocale locale = AppLocale.en,
    double textScale = 1,
    Map<String, WidgetBuilder> routes = const {},
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState()..setLocale(locale),
        ),
        ChangeNotifierProvider<AccessibilitySettings>(
          create: (_) => AccessibilitySettings(),
        ),
        ChangeNotifierProvider<ReadAloudService>(
          create: (_) => ReadAloudService(),
        ),
        ChangeNotifierProvider<AuthState>(
          create: (context) => AuthState(
            appState: context.read<AppState>(),
            authService: auth,
            userProfileService: FakeUserProfileService(),
          ),
        ),
        ChangeNotifierProvider<ReportsProvider>(
          create: (_) {
            reports = ReportsProvider(
              service: ConditionReportService(repository: repository),
              authService: auth,
            );
            return reports;
          },
        ),
      ],
      child: AppStringsScope(
        locale: locale,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: home,
          routes: {
            Routes.reportConfirm: (_) =>
                const Scaffold(body: Text('CONFIRMATION SCREEN')),
            Routes.home: (_) => const Scaffold(body: Text('HOME SCREEN')),
            Routes.reportForm: (_) =>
                const Scaffold(body: Text('REPORT FORM SCREEN')),
            ...routes,
          },
        ),
      ),
    );
  }
}
