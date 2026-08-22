import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/localization/locale.dart';
import 'core/routes.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding/role_select_screen.dart';
import 'screens/onboarding/signup_access_screen.dart';
import 'screens/onboarding/signup_basic_screen.dart';
import 'screens/onboarding/signup_contacts_screen.dart';
import 'screens/passenger/home_screen.dart';
import 'screens/passenger/plan_detail_screen.dart';
import 'screens/passenger/plan_results_screen.dart';
import 'screens/passenger/plan_search_screen.dart';
import 'screens/passenger/share_active_screen.dart';
import 'screens/passenger/share_setup_screen.dart';
import 'screens/profile/profile_access_screen.dart';
import 'screens/profile/profile_contacts_screen.dart';
import 'screens/profile/profile_home_screen.dart';
import 'screens/profile/profile_sharing_screen.dart';
import 'screens/reports/report_confirm_screen.dart';
import 'screens/reports/report_form_screen.dart';
import 'screens/reports/report_mine_screen.dart';
import 'screens/volunteer/volunteer_feed_screen.dart';
import 'screens/volunteer/volunteer_home_screen.dart';
import 'screens/volunteer/volunteer_profile_screen.dart';

class ColomboPalApp extends StatelessWidget {
  const ColomboPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return AppStringsScope(
            locale: state.locale,
            child: MaterialApp(
              title: 'Colombo Pal',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.system,
              initialRoute: Routes.roleSelect,
              routes: {
                Routes.roleSelect: (_) => const RoleSelectScreen(),
                Routes.signupBasic: (_) => const SignupBasicScreen(),
                Routes.signupAccess: (_) => const SignupAccessScreen(),
                Routes.signupContacts: (_) => const SignupContactsScreen(),

                Routes.home: (_) => const HomeScreen(),
                Routes.planSearch: (_) => const PlanSearchScreen(),
                Routes.planResults: (_) => const PlanResultsScreen(),
                Routes.planDetail: (_) => const PlanDetailScreen(),
                Routes.shareSetup: (_) => const ShareSetupScreen(),
                Routes.shareActive: (_) => const ShareActiveScreen(),

                Routes.reportForm: (_) => const ReportFormScreen(),
                Routes.reportConfirm: (_) => const ReportConfirmScreen(),
                Routes.reportMine: (_) => const ReportMineScreen(),

                Routes.profileHome: (_) => const ProfileHomeScreen(),
                Routes.profileContacts: (_) => const ProfileContactsScreen(),
                Routes.profileAccess: (_) => const ProfileAccessScreen(),
                Routes.profileSharing: (_) => const ProfileSharingScreen(),

                Routes.volunteerHome: (_) => const VolunteerHomeScreen(),
                Routes.volunteerFeed: (_) => const VolunteerFeedScreen(),
                Routes.volunteerProfile: (_) => const VolunteerProfileScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}
