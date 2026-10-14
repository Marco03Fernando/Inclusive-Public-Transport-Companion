import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin/providers/admin_auth_provider.dart';
import 'admin/providers/admin_reports_provider.dart';
import 'admin/repositories/firebase_admin_report_repository.dart';
import 'admin/screens/admin_gate.dart';
import 'admin/services/admin_auth_service.dart';
import 'admin/services/admin_report_service.dart';
import 'core/localization/locale.dart';
import 'core/routes.dart';
import 'core/state/accessibility_settings.dart';
import 'core/state/app_state.dart';
import 'core/state/auth_state.dart';
import 'core/theme/app_theme.dart';
import 'models/google_route.dart';
import 'models/public_condition_report.dart';
import 'models/report_filters.dart';
import 'providers/community_reports_provider.dart';
import 'providers/reports_provider.dart';
import 'repositories/community_report_repository.dart';
import 'repositories/firebase_community_report_repository.dart';
import 'repositories/firebase_condition_report_repository.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/profile/accessibility_settings_screen.dart';
import 'screens/onboarding/role_select_screen.dart';
import 'screens/onboarding/signup_access_screen.dart';
import 'screens/onboarding/signup_basic_screen.dart';
import 'screens/onboarding/signup_contacts_screen.dart';
import 'screens/passenger/home_screen.dart';
import 'screens/passenger/plan_detail_screen.dart';
import 'screens/passenger/plan_results_screen.dart';
import 'screens/passenger/plan_search_screen.dart';
import 'screens/passenger/request_assistance_screen.dart';
import 'screens/passenger/request_status_screen.dart';
import 'screens/passenger/share_active_screen.dart';
import 'screens/passenger/share_setup_screen.dart';
import 'screens/profile/profile_access_screen.dart';
import 'screens/profile/profile_contacts_screen.dart';
import 'screens/profile/profile_home_screen.dart';
import 'screens/profile/profile_sharing_screen.dart';
import 'screens/reports/report_confirm_screen.dart';
import 'screens/reports/report_form_screen.dart';
import 'screens/reports/report_mine_screen.dart';
import 'screens/volunteer/assistance_requests_screen.dart';
import 'screens/volunteer/community_report_details_screen.dart';
import 'screens/volunteer/volunteer_feed_screen.dart';
import 'screens/volunteer/volunteer_home_screen.dart';
import 'screens/volunteer/volunteer_profile_screen.dart';
import 'services/auth_service.dart';
import 'services/condition_report_service.dart';
import 'services/read_aloud_service.dart';
import 'widgets/auth_gate.dart';

class ColomboPalApp extends StatelessWidget {
  const ColomboPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),

        // ---- Accessibility: text size, high contrast, Read Aloud ----
        ChangeNotifierProvider<AccessibilitySettings>(
          create: (_) => AccessibilitySettings(),
        ),
        ChangeNotifierProvider<ReadAloudService>(
          create: (_) => ReadAloudService(),
        ),

        // One AuthService shared by AuthState (sign-in/up/out) and
        // ReportsProvider (who "the current user" is).
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<AuthState>(
          create: (context) => AuthState(
            appState: context.read<AppState>(),
            authService: context.read<AuthService>(),
          ),
        ),

        // ---- Condition reports: Screen → Provider → Service → Repository → Firebase ----
        Provider<ConditionReportService>(
          create: (_) => ConditionReportService(
            repository: FirebaseConditionReportRepository(),
          ),
        ),
        // Loads the signed-in user's own reports and clears them on
        // sign-out, so one account never sees another account's list.
        ChangeNotifierProxyProvider<AuthState, ReportsProvider>(
          create: (context) => ReportsProvider(
            service: context.read<ConditionReportService>(),
            authService: context.read<AuthService>(),
          ),
          update: (context, auth, reports) {
            reports!.syncSession(userId: auth.isAdmin ? null : auth.uid);
            return reports;
          },
        ),

        // ---- Community Reports: published copies only (read-only) ----
        Provider<CommunityReportRepository>(
          create: (_) => FirebaseCommunityReportRepository(),
        ),

        // ---- Admin module (lib/admin/) ----
        Provider<AdminAuthService>(create: (_) => AdminAuthService()),
        Provider<AdminReportService>(
          create: (_) {
            final repository = FirebaseAdminReportRepository();
            return AdminReportService(
              repository: repository,
              publication: repository,
            );
          },
        ),
        // Independently verifies users/{uid}.role == "admin".
        ChangeNotifierProvider<AdminAuthProvider>(
          create: (context) =>
              AdminAuthProvider(service: context.read<AdminAuthService>()),
        ),
        // Live subscription to ALL reports that only runs while a VERIFIED
        // admin is signed in; cancelled + cleared on sign-out.
        ChangeNotifierProxyProvider<AdminAuthProvider, AdminReportsProvider>(
          create: (context) =>
              AdminReportsProvider(service: context.read<AdminReportService>()),
          update: (context, adminAuth, reports) {
            reports!.syncSession(isAdmin: adminAuth.isAdmin);
            return reports;
          },
        ),
      ],
      // Rebuilds only when the language, theme mode or accessibility
      // settings change — not on every AppState notification (SOS hold
      // progress, signup drafts, ...).
      child: Builder(
        builder: (context) {
          final locale = context.select<AppState, AppLocale>((s) => s.locale);
          final themeMode = context.select<AppState, ThemeMode>(
            (s) => s.themeMode,
          );
          final a11y = context.watch<AccessibilitySettings>();
          return AppStringsScope(
            locale: locale,
            child: MaterialApp(
              title: 'Colombo Pal',
              debugShowCheckedModeBanner: false,
              // In-app High Contrast Mode swaps the palettes; the
              // highContrast* themes also apply when the OS asks for high
              // contrast (e.g. iOS "Increase Contrast").
              theme: a11y.highContrast
                  ? AppTheme.highContrastLight
                  : AppTheme.light,
              darkTheme: a11y.highContrast
                  ? AppTheme.highContrastDark
                  : AppTheme.dark,
              highContrastTheme: AppTheme.highContrastLight,
              highContrastDarkTheme: AppTheme.highContrastDark,
              themeMode: themeMode,
              navigatorObservers: [
                context.read<ReadAloudService>().navigatorObserver,
              ],
              // App-wide text size: the larger of the OS text size and the
              // in-app preset (Standard 100% / Large 125% / Extra Large
              // 150%). Never smaller than the OS setting, and no upper cap,
              // so users who need very large system text keep it.
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: a11y.textScalerFor(mq.textScaler),
                  ),
                  child: child!,
                );
              },
              home: const AuthGate(),
              routes: {
                Routes.roleSelect: (_) => const RoleSelectScreen(),
                Routes.login: (_) => const LoginScreen(),
                Routes.signupBasic: (_) => const SignupBasicScreen(),
                Routes.signupAccess: (_) => const SignupAccessScreen(),
                Routes.signupContacts: (_) => const SignupContactsScreen(),

                Routes.home: (_) => const HomeScreen(),
                Routes.planSearch: (_) => const PlanSearchScreen(),
                Routes.planResults: (_) => const PlanResultsScreen(),
                Routes.planDetail: (context) {
                  final route =
                      ModalRoute.of(context)!.settings.arguments as GoogleRoute;

                  return PlanDetailScreen(route: route);
                },
                Routes.shareSetup: (_) => const ShareSetupScreen(),
                Routes.shareActive: (_) => const ShareActiveScreen(),

                Routes.reportForm: (_) => const ReportFormScreen(),
                Routes.reportConfirm: (_) => const ReportConfirmScreen(),
                // Optional argument: the StatusFilter to open with (e.g.
                // the dashboard's "Verified by admin" card passes verified).
                Routes.reportMine: (context) {
                  final initial = ModalRoute.of(context)?.settings.arguments;
                  return ReportMineScreen(
                    initialStatus: initial is StatusFilter
                        ? initial
                        : StatusFilter.all,
                  );
                },

                Routes.profileHome: (_) => const ProfileHomeScreen(),
                Routes.profileContacts: (_) => const ProfileContactsScreen(),
                Routes.profileAccess: (_) => const ProfileAccessScreen(),
                Routes.profileSharing: (_) => const ProfileSharingScreen(),
                Routes.accessibilitySettings: (_) =>
                    const AccessibilitySettingsScreen(),
                Routes.requestAssistance: (_) =>
                    const RequestAssistanceScreen(),
                Routes.requestStatus: (_) => const RequestStatusScreen(),

                Routes.volunteerHome: (_) => const VolunteerHomeScreen(),
                // The feed's listener lives only while the screen is open;
                // Report Details is pushed on top, so filters survive it.
                Routes.volunteerFeed: (context) =>
                    ChangeNotifierProvider<CommunityReportsProvider>(
                      create: (context) => CommunityReportsProvider(
                        repository: context.read<CommunityReportRepository>(),
                      )..refresh(),
                      child: const VolunteerFeedScreen(),
                    ),
                Routes.communityReportDetails: (context) =>
                    CommunityReportDetailsScreen(
                      initialReport:
                          ModalRoute.of(context)!.settings.arguments
                              as PublicConditionReport,
                    ),
                Routes.volunteerProfile: (_) => const VolunteerProfileScreen(),
                Routes.volunteerAssistanceRequests: (_) =>
                    const AssistanceRequestsScreen(),

                Routes.admin: (_) => const AdminGate(),
              },
            ),
          );
        },
      ),
    );
  }
}
