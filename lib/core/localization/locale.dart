/// Lightweight EN/SI string lookup that mirrors the design's `TR` table.
///
/// Kept as a plain Dart map rather than Flutter's `intl`/ARB codegen so the
/// UI-only build has no generated-code step; the shape (one key per string,
/// one map per locale) is intentionally close to an ARB file so a later
/// migration to `flutter gen-l10n` is a straight port — see [AppStrings.en]
/// and [AppStrings.si].
library;

import 'package:flutter/widgets.dart';

enum AppLocale { en, si }

class AppStrings {
  AppStrings._();

  static const Map<String, String> en = {
    'appTagline': 'Travel safely and confidently around Colombo',
    'registeringAs': 'I am registering as a',
    'rolePassenger': 'Passenger',
    'roleVolunteer': 'Volunteer',
    'passengerDesc': 'Elderly or disabled traveller looking for safer journeys',
    'volunteerDesc': 'Help keep transport information accurate for everyone',
    'haveAccount': 'Already have an account?',
    'logIn': 'Log in',
    'signUp': 'Sign Up',
    'yourDetails': 'Your details',
    'personaliseNote': 'We use this to personalise routes and alerts',
    'fullName': 'Full name',
    'phoneNumber': 'Phone number',
    'dob': 'Date of birth',
    'continueBtn': 'Continue',
    'accessTitle': 'Accessibility & medical needs',
    'accessNote': 'Helps us route you and brief your emergency contacts',
    'medicalNotesLabel': 'Additional medical notes (optional)',
    'medicalPlaceholder':
        'e.g. uses a hearing aid, prone to dizziness on long stairs',
    'contactsTitle': 'Emergency contacts',
    'contactsNote':
        'Add the two people we should notify. Required to finish setup.',
    'addAnotherContact': '+ Add another contact',
    'finishSetup': 'Finish setup',
    'contactWord': 'Contact',
    'goodAfternoon': 'Good afternoon',
    'routeAlertLabel': 'Route alert:',
    'planJourney': 'Plan Journey',
    'planJourneyDesc': 'Find an accessible route',
    'shareJourney': 'Share Journey',
    'shareJourneyDesc': 'Let family follow along',
    'reportCondition': 'Report a Condition',
    'reportConditionDescHome': 'Tell others about a bus, station or rest area',
    'recentActivity': 'Recent activity',
    'routePreferences': 'Route preferences',
    'findRoutes': 'Find routes',
    'routeOptionsTitle': 'Route Options',
    'stepByStep': 'Step by step',
    'reportedAlongRoute': 'Reported along this route',
    'shareWith': 'Share with',
    'journeyLabel': 'Journey:',
    'startSharing': 'Start sharing',
    'shareIntro':
        "Share your live location with a trusted contact for this journey. They'll be notified when it starts and ends.",
    'journeyInProgress': 'Journey in progress',
    'endJourney': 'End journey',
    'notifiedStarted': 'was notified this journey started · elapsed',
    'whatReporting': 'What are you reporting?',
    'vehicleOrLocation': 'Vehicle number or location',
    'vehiclePlaceholder': 'e.g. NB-4521 or Maradana Station',
    'conditionType': 'Condition type',
    'description': 'Description',
    'descPlaceholder': 'Add a short description of what you observed',
    'photoOptional': 'Photo (optional)',
    'attachPhoto': '+ attach photo',
    'submitReport': 'Submit report',
    'reportSubmitted': 'Report submitted',
    'reportSubmittedNote':
        "Thank you. An administrator will review this report before it's marked Verified.",
    'underReview': 'Under Review',
    'verified': 'Verified',
    'viewMyReports': 'View my reports',
    'backToHomeLabel': 'Back to home',
    'myReportsTitle': 'My Reports',
    'emergencyContactsTitle': 'Emergency Contacts',
    'emergencyContactsNote':
        'These contacts are notified when you use Share Journey or press SOS.',
    'addContact': '+ Add contact',
    'editWord': 'Edit',
    'accessPrefsTitle': 'Accessibility Preferences',
    'locationSharingTitle': 'Location Sharing',
    'autoShareTitle': 'Auto-share on every journey',
    'autoShareNote': 'Skip the setup step and share by default',
    'sharingHistory': 'Sharing history',
    'languageWord': 'Language',
    'englishWord': 'English',
    'sinhalaWord': 'Sinhala',
    'logOut': 'Log out',
    'welcomeBack': 'Welcome back',
    'reportsSubmitted': 'Reports submitted',
    'verifiedByAdmin': 'Verified by admin',
    'volunteerReportDesc': 'Help keep transport info accurate',
    'communityReports': 'Community Reports',
    'communityReportsDesc': "Browse what's been reported nearby",
    'allFilter': 'All',
    'busesFilter': 'Buses',
    'stationsFilter': 'Stations',
    'activeArea': 'Active area',
    'notificationPrefs': 'Notification preferences',
    'sosHoldTitle': 'Press and hold for 3 seconds',
    'sosHoldNote': 'This alerts your emergency contacts with your live location',
    'cancel': 'Cancel',
    'helpOnWay': 'Help is on the way',
    'helpOnWayNote': 'Nimal Perera and Kumari Silva were sent your current location',
    'callAmbulance': 'Call 1990 Suwa Seriya Ambulance',
    'imSafe': "I'm safe now",
    'navHome': 'Home',
    'navPlan': 'Plan',
    'navShare': 'Share',
    'navReport': 'Report',
    'navProfile': 'Profile',
    'navReports': 'Reports',
    'needWheelchair': 'Wheelchair user',
    'needVisual': 'Visual impairment',
    'needHearing': 'Hearing impairment',
    'needMobility': 'Uses a mobility aid (cane / walker)',
    'needCognitive': 'Cognitive support needed',
    'targetBus': 'Bus',
    'targetStation': 'Station',
    'targetRest': 'Rest area',
    'targetOther': 'Other',
    'condCrowded': 'Crowded',
    'condLift': 'Broken lift / ramp',
    'condUnsafe': 'Unsafe driving',
    'condClean': 'Cleanliness',
    'condOther': 'Other',
    'filterWheelchair': 'Wheelchair accessible',
    'filterLowfloor': 'Low-floor bus',
    'filterStairs': 'Avoid stairs',
    'filterQuiet': 'Less crowded',
    'mapLiveRoute': 'MAP · live route view',
    'mapLivePosition': 'MAP · your live position',
    'accessSuffix': 'access',
  };

  static const Map<String, String> si = {
    'appTagline': 'කොළඹ ආරක්ෂිතව හා විශ්වාසයෙන් සංචාරය කරන්න',
    'registeringAs': 'මම ලියාපදිංචි වන්නේ',
    'rolePassenger': 'මගියා',
    'roleVolunteer': 'ස්වේච්ඡා සේවක',
    'passengerDesc': 'ආරක්ෂිත සංචාර සොයන වැඩිහිටි හෝ ආබාධිත මගීන්',
    'volunteerDesc':
        'සියලුදෙනාටම නිවැරදි ප්‍රවාහන තොරතුරු පවත්වා ගැනීමට උදව් කරන්න',
    'haveAccount': 'දැනටමත් ගිණුමක් තිබේද?',
    'logIn': 'පිවිසෙන්න',
    'signUp': 'ලියාපදිංචි වන්න',
    'yourDetails': 'ඔබේ තොරතුරු',
    'personaliseNote':
        'මාර්ග සහ අනතුරු ඇඟවීම් ඔබට අනුව සකස් කිරීමට මෙය භාවිත කරමු',
    'fullName': 'සම්පූර්ණ නම',
    'phoneNumber': 'දුරකථන අංකය',
    'dob': 'උප්පැන්න දිනය',
    'continueBtn': 'ඉදිරියට',
    'accessTitle': 'ප්‍රවේශ්‍යතා සහ වෛද්‍ය අවශ්‍යතා',
    'accessNote':
        'ඔබට මාර්ග යෝජනා කිරීමට හා හදිසි සම්බන්ධතා දැනුවත් කිරීමට උපකාරී වේ',
    'medicalNotesLabel': 'අමතර වෛද්‍ය සටහන් (විකල්ප)',
    'medicalPlaceholder':
        'උදා: ශ්‍රවණ උපකරණයක් භාවිතා කරයි, දිගු පඩිපෙළවල කරකැවිල්ල ඇතිවිය හැක',
    'contactsTitle': 'හදිසි සම්බන්ධතා',
    'contactsNote':
        'අප දැනුවත් කළ යුතු පුද්ගලයන් දෙදෙනා එක් කරන්න. සැකසුම අවසන් කිරීමට අවශ්‍යයි.',
    'addAnotherContact': '+ තවත් සම්බන්ධතාවක් එක් කරන්න',
    'finishSetup': 'සැකසුම අවසන් කරන්න',
    'contactWord': 'සම්බන්ධතාව',
    'goodAfternoon': 'සුභ දහවලක්',
    'routeAlertLabel': 'මාර්ග අනතුරු ඇඟවීම:',
    'planJourney': 'සංචාරය සැලසුම් කරන්න',
    'planJourneyDesc': 'ප්‍රවේශ විය හැකි මාර්ගයක් සොයන්න',
    'shareJourney': 'සංචාරය බෙදාගන්න',
    'shareJourneyDesc': 'පවුලට ඔබ සමඟ අනුගමනය කිරීමට ඉඩ දෙන්න',
    'reportCondition': 'තත්ත්වයක් වාර්තා කරන්න',
    'reportConditionDescHome':
        'බස් රථයක්, ස්ථානයක් හෝ විවේක ස්ථානයක් ගැන අන් අයට කියන්න',
    'recentActivity': 'මෑත ක්‍රියාකාරකම්',
    'routePreferences': 'මාර්ග අභිප්‍රේත',
    'findRoutes': 'මාර්ග සොයන්න',
    'routeOptionsTitle': 'මාර්ග විකල්ප',
    'stepByStep': 'පියවරෙන් පියවර',
    'reportedAlongRoute': 'මෙම මාර්ගය දිගේ වාර්තා වූ තත්ත්ව',
    'shareWith': 'සමඟ බෙදාගන්න',
    'journeyLabel': 'සංචාරය:',
    'startSharing': 'බෙදාගැනීම අරඹන්න',
    'shareIntro':
        'මෙම සංචාරය සඳහා ඔබේ සජීවී ස්ථානය විශ්වාසී සම්බන්ධතාවක් සමඟ බෙදාගන්න. එය ආරම්භ වූ විටත් අවසන් වූ විටත් ඔවුන් දැනුවත් කරනු ලැබේ.',
    'journeyInProgress': 'සංචාරය සිදුවෙමින් පවතී',
    'endJourney': 'සංචාරය අවසන් කරන්න',
    'notifiedStarted': 'මෙම සංචාරය ආරම්භ වූ බව දැනුම් දෙන ලදී · ගතවූ කාලය',
    'whatReporting': 'ඔබ වාර්තා කරන්නේ කුමක්ද?',
    'vehicleOrLocation': 'වාහන අංකය හෝ ස්ථානය',
    'vehiclePlaceholder': 'උදා: NB-4521 හෝ මරදාන දුම්රිය ස්ථානය',
    'conditionType': 'තත්ත්ව වර්ගය',
    'description': 'විස්තරය',
    'descPlaceholder': 'ඔබ දුටු දේ පිළිබඳ කෙටි විස්තරයක් එක් කරන්න',
    'photoOptional': 'ඡායාරූපය (විකල්ප)',
    'attachPhoto': '+ ඡායාරූපයක් අමුණන්න',
    'submitReport': 'වාර්තාව යවන්න',
    'reportSubmitted': 'වාර්තාව යවනු ලදී',
    'reportSubmittedNote':
        'ස්තුතියි. මෙය තහවුරු කළ ලෙස සලකුණු කිරීමට පෙර පාලකයෙකු මෙම වාර්තාව සමාලෝචනය කරනු ඇත.',
    'underReview': 'සමාලෝචනයේ පවතී',
    'verified': 'තහවුරු කර ඇත',
    'viewMyReports': 'මගේ වාර්තා බලන්න',
    'backToHomeLabel': 'නිවසට ආපසු',
    'myReportsTitle': 'මගේ වාර්තා',
    'emergencyContactsTitle': 'හදිසි සම්බන්ධතා',
    'emergencyContactsNote':
        'ඔබ සංචාරය බෙදාගැනීම භාවිතා කරන විට හෝ SOS ඔබන විට මෙම සම්බන්ධතා දැනුවත් කරනු ලැබේ.',
    'addContact': '+ සම්බන්ධතාවක් එක් කරන්න',
    'editWord': 'සංස්කරණය',
    'accessPrefsTitle': 'ප්‍රවේශ්‍යතා අභිප්‍රේත',
    'locationSharingTitle': 'ස්ථාන බෙදාගැනීම',
    'autoShareTitle': 'සෑම සංචාරයකදීම ස්වයංක්‍රීයව බෙදාගන්න',
    'autoShareNote': 'සැකසුම් පියවර මගහැර පෙරනිමියෙන් බෙදාගන්න',
    'sharingHistory': 'බෙදාගැනීමේ ඉතිහාසය',
    'languageWord': 'භාෂාව',
    'englishWord': 'ඉංග්‍රීසි',
    'sinhalaWord': 'සිංහල',
    'logOut': 'ඉවත් වන්න',
    'welcomeBack': 'ආයුබෝවන්, ආපසු පිළිගනිමු',
    'reportsSubmitted': 'යැවූ වාර්තා',
    'verifiedByAdmin': 'පාලක විසින් තහවුරු කරන ලද',
    'volunteerReportDesc': 'ප්‍රවාහන තොරතුරු නිවැරදිව පවත්වා ගැනීමට උදව් කරන්න',
    'communityReports': 'ප්‍රජා වාර්තා',
    'communityReportsDesc': 'ආසන්නයේ වාර්තා වී ඇති දේ බලන්න',
    'allFilter': 'සියල්ල',
    'busesFilter': 'බස්',
    'stationsFilter': 'ස්ථාන',
    'activeArea': 'ක්‍රියාකාරී ප්‍රදේශය',
    'notificationPrefs': 'දැනුම්දීම් අභිප්‍රේත',
    'sosHoldTitle': 'තත්පර 3ක් අල්ලාගෙන සිටින්න',
    'sosHoldNote': 'මෙය ඔබේ සජීවී ස්ථානය සමඟ ඔබේ හදිසි සම්බන්ධතා දැනුවත් කරයි',
    'cancel': 'අවලංගු කරන්න',
    'helpOnWay': 'උදව් එනවා',
    'helpOnWayNote':
        'නිමල් පෙරේරා සහ කුමාරි සිල්වා වෙත ඔබේ වර්තමාන ස්ථානය යවනු ලදී',
    'callAmbulance': '1990 සුව සැරිය ගිලන් රථය අමතන්න',
    'imSafe': 'මම දැන් ආරක්ෂිතයි',
    'navHome': 'නිවස',
    'navPlan': 'සැලසුම',
    'navShare': 'බෙදාගන්න',
    'navReport': 'වාර්තා කරන්න',
    'navProfile': 'පැතිකඩ',
    'navReports': 'වාර්තා',
    'needWheelchair': 'රෝද පුටු භාවිතා කරන්නෙක්',
    'needVisual': 'දෘශ්‍ය දුබලතාවය',
    'needHearing': 'ශ්‍රවණ දුබලතාවය',
    'needMobility': 'චලන ආධාරකයක් භාවිතා කරයි (බැටනයක් / walker)',
    'needCognitive': 'සංජානන සහාය අවශ්‍යයි',
    'targetBus': 'බස් රථය',
    'targetStation': 'ස්ථානය',
    'targetRest': 'විවේක ස්ථානය',
    'targetOther': 'වෙනත්',
    'condCrowded': 'තදබදය',
    'condLift': 'අබලන් වූ සෝපානය / රැම්පය',
    'condUnsafe': 'අනාරක්ෂිත රියදුරු ක්‍රියාව',
    'condClean': 'පිරිසිදුකම',
    'condOther': 'වෙනත්',
    'filterWheelchair': 'රෝද පුටු ප්‍රවේශ්‍ය',
    'filterLowfloor': 'පහත් මට්ටමේ බස් රථය',
    'filterStairs': 'පඩිපෙළ මගහරින්න',
    'filterQuiet': 'අඩු තදබදය',
    'mapLiveRoute': 'සිතියම · සජීවී මාර්ග දැක්ම',
    'mapLivePosition': 'සිතියම · ඔබේ සජීවී ස්ථානය',
    'accessSuffix': 'ප්‍රවේශ්‍යතාව',
  };

  static Map<String, String> forLocale(AppLocale locale) =>
      locale == AppLocale.en ? en : si;
}

/// `t('key')` accessor scoped to the current [AppLocale], read from an
/// [InheritedWidget] set up in `app.dart` so screens never poke `AppState`
/// directly just to read strings.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.locale,
    required super.child,
  });

  final AppLocale locale;

  static AppStringsScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    assert(scope != null, 'AppStringsScope not found in context');
    return scope!;
  }

  String call(String key) => AppStrings.forLocale(locale)[key] ?? key;

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      oldWidget.locale != locale;
}

extension AppStringsContext on BuildContext {
  /// Usage: `context.t('planJourney')`.
  String t(String key) => AppStringsScope.of(this)(key);
}
