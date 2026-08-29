import 'state/app_state.dart';

/// Route names mirror the design's screen ids 1:1 so the mapping in the
/// design's `NOTES` comment (one screen id -> one widget) stays legible.
class Routes {
  Routes._();

  static const roleSelect = '/role-select';
  static const login = '/login';
  static const signupBasic = '/signup-basic';
  static const signupAccess = '/signup-access';
  static const signupContacts = '/signup-contacts';

  static const home = '/home';
  static const planSearch = '/plan-search';
  static const planResults = '/plan-results';
  static const planDetail = '/plan-detail';
  static const shareSetup = '/share-setup';
  static const shareActive = '/share-active';

  static const reportForm = '/report-form';
  static const reportConfirm = '/report-confirm';
  static const reportMine = '/report-mine';

  static const profileHome = '/profile-home';
  static const profileContacts = '/profile-contacts';
  static const profileAccess = '/profile-access';
  static const profileSharing = '/profile-sharing';

  static const requestAssistance = '/request-assistance';
  static const requestStatus = '/request-status';

  static const volunteerHome = '/volunteer-home';
  static const volunteerFeed = '/volunteer-feed';
  static const volunteerProfile = '/volunteer-profile';
  static const volunteerAssistanceRequests = '/volunteer-assistance-requests';

  static const onboardingRoutes = {roleSelect, login, signupBasic, signupAccess, signupContacts};

  /// Ports the design's `sosEligibleScreens` list: SOS is reachable from any
  /// signed-in screen, except the transient report-confirm success state and
  /// onboarding (no account yet). Volunteers are still people out in transit
  /// on their own, so they get the same safety net as passengers.
  static const _sosEligiblePassenger = {
    home, planSearch, planResults, planDetail,
    shareSetup, shareActive,
    reportForm, reportMine,
    profileHome, profileContacts, profileAccess, profileSharing,
    requestAssistance, requestStatus,
  };

  static const _sosEligibleVolunteer = {
    volunteerHome, volunteerFeed, volunteerProfile, volunteerAssistanceRequests,
    reportForm,
  };

  static bool showsBottomNav(String route) => !onboardingRoutes.contains(route);

  static bool showsSos(String route, AppRole role) => switch (role) {
        AppRole.passenger => _sosEligiblePassenger.contains(route),
        AppRole.volunteer => _sosEligibleVolunteer.contains(route),
      };
}

enum BottomTab { home, plan, share, report, reports, profile }

class TabDef {
  const TabDef(this.tab, this.target, this.matches);

  final BottomTab tab;
  final String target;
  final Set<String> matches;
}

const passengerTabs = [
  TabDef(BottomTab.home, Routes.home, {Routes.home}),
  TabDef(BottomTab.plan, Routes.planSearch, {Routes.planSearch, Routes.planResults, Routes.planDetail}),
  TabDef(BottomTab.share, Routes.shareSetup, {Routes.shareSetup, Routes.shareActive}),
  TabDef(BottomTab.report, Routes.reportForm, {Routes.reportForm, Routes.reportConfirm, Routes.reportMine}),
  TabDef(BottomTab.profile, Routes.profileHome, {
    Routes.profileHome, Routes.profileContacts, Routes.profileAccess, Routes.profileSharing,
    Routes.requestAssistance, Routes.requestStatus,
  }),
];

const volunteerTabs = [
  TabDef(BottomTab.home, Routes.volunteerHome, {Routes.volunteerHome}),
  TabDef(BottomTab.reports, Routes.volunteerFeed, {Routes.volunteerFeed}),
  TabDef(BottomTab.report, Routes.reportForm, {Routes.reportForm, Routes.reportConfirm}),
  TabDef(BottomTab.profile, Routes.volunteerProfile,
      {Routes.volunteerProfile, Routes.volunteerAssistanceRequests}),
];
