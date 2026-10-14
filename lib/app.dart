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
import 'core/state/app_state.dart';
import 'core/state/auth_state.dart';
import 'core/theme/app_theme.dart';
import 'models/google_route.dart';
import 'providers/reports_provider.dart';
import 'repositories/firebase_condition_report_repository.dart';
import 'screens/onboarding/login_screen.dart';
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
import 'screens/volunteer/volunteer_feed_screen.dart';
import 'screens/volunteer/volunteer_home_screen.dart';
import 'screens/volunteer/volunteer_profile_screen.dart';
import 'services/auth_service.dart';
import 'services/condition_report_service.dart';
import 'widgets/auth_gate.dart';
import 'widgets/sos_trigger_host.dart';

class ColomboPalApp extends StatelessWidget {
  const ColomboPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),

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

        // ---- Admin module (lib/admin/) ----
        Provider<AdminAuthService>(create: (_) => AdminAuthService()),
        Provider<AdminReportService>(
          create: (_) =>
              AdminReportService(repository: FirebaseAdminReportRepository()),
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
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return AppStringsScope(
            locale: state.locale,
            child: MaterialApp(
              title: 'Colombo Pal',
              debugShowCheckedModeBanner: false,
              navigatorKey: rootNavigatorKey,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: state.themeMode,
              // Large system text scale support for elderly users:
              // respects the device text-size setting up to a cap so
              // layouts don't break.
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: mq.textScaler.clamp(
                      minScaleFactor: 1.0,
                      maxScaleFactor: 1.3,
                    ),
                  ),
                  child: SosTriggerHost(child: child ?? const SizedBox.shrink()),
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
                Routes.reportMine: (_) => const ReportMineScreen(),

                Routes.profileHome: (_) => const ProfileHomeScreen(),
                Routes.profileContacts: (_) => const ProfileContactsScreen(),
                Routes.profileAccess: (_) => const ProfileAccessScreen(),
                Routes.profileSharing: (_) => const ProfileSharingScreen(),
                Routes.requestAssistance: (_) =>
                    const RequestAssistanceScreen(),
                Routes.requestStatus: (_) => const RequestStatusScreen(),

                Routes.volunteerHome: (_) => const VolunteerHomeScreen(),
                Routes.volunteerFeed: (_) => const VolunteerFeedScreen(),
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
