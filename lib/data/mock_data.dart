import '../models/access_need.dart';
import '../models/chip_option.dart';
import '../models/condition_report.dart';
import '../models/contact.dart';
import '../models/route_option.dart';

/// Static mock data ported 1:1 from the design's `renderVals()`. No network
/// or persistence — this is UI-only, so the same fixtures back every screen.

const defaultAccessNeeds = [
  AccessNeed(id: 'wheelchair', labelKey: 'needWheelchair', checked: true),
  AccessNeed(id: 'visual', labelKey: 'needVisual', checked: false),
  AccessNeed(id: 'hearing', labelKey: 'needHearing', checked: false),
  AccessNeed(id: 'mobility', labelKey: 'needMobility', checked: true),
  AccessNeed(id: 'cognitive', labelKey: 'needCognitive', checked: false),
];

const planFilterOptions = [
  ChipOption(id: 'wheelchair', labelKey: 'filterWheelchair'),
  ChipOption(id: 'lowfloor', labelKey: 'filterLowfloor'),
  ChipOption(id: 'stairs', labelKey: 'filterStairs'),
  ChipOption(id: 'quiet', labelKey: 'filterQuiet'),
];

const reportTargetOptions = [
  ChipOption(id: 'bus', labelKey: 'targetBus'),
  ChipOption(id: 'station', labelKey: 'targetStation'),
  ChipOption(id: 'rest', labelKey: 'targetRest'),
  ChipOption(id: 'other', labelKey: 'targetOther'),
];

const reportTypeOptions = [
  ChipOption(id: 'crowded', labelKey: 'condCrowded'),
  ChipOption(id: 'lift', labelKey: 'condLift'),
  ChipOption(id: 'unsafe', labelKey: 'condUnsafe'),
  ChipOption(id: 'clean', labelKey: 'condClean'),
  ChipOption(id: 'other', labelKey: 'condOther'),
];

const mockContacts = [
  Contact(name: 'Nimal Perera', relation: 'Son', phone: '+94 77 123 4567'),
  Contact(name: 'Kumari Silva', relation: 'Daughter', phone: '+94 71 987 6543'),
];

const mockRouteOptions = [
  RouteOption(
    mode: 'Bus 138 + Coastal Line',
    duration: '42 min',
    transfers: 1,
    accessScore: AccessScore.high,
    crowding: 'Moderate',
  ),
  RouteOption(
    mode: 'Bus 100 direct',
    duration: '55 min',
    transfers: 0,
    accessScore: AccessScore.medium,
    crowding: 'Low',
  ),
  RouteOption(
    mode: 'Tuk + Bus 138',
    duration: '38 min',
    transfers: 1,
    accessScore: AccessScore.medium,
    crowding: 'High',
  ),
];

const mockRouteSteps = [
  RouteStep(n: 1, text: 'Walk to Nugegoda Bus Stand', detail: '350 m, level pavement'),
  RouteStep(
    n: 2,
    text: 'Bus 138 to Fort',
    detail: 'Low-floor, wheelchair ramp available · 25 min',
  ),
  RouteStep(
    n: 3,
    text: 'Fort Railway Station',
    detail: 'Lift available, tactile paving, rest area on Platform 1',
  ),
  RouteStep(
    n: 4,
    text: 'Coastal Line to Bambalapitiya',
    detail: '12 min, priority seating near door',
  ),
];

const mockRouteConditions = [
  ConditionReport(
    title: 'Crowded during peak hours',
    location: 'Bus 138, 5–6:30pm',
    status: ReportStatus.verified,
  ),
  ConditionReport(
    title: 'Lift out of service',
    location: 'Fort Station, Platform 2',
    status: ReportStatus.underReview,
  ),
];

const mockMyReports = [
  ConditionReport(
    title: 'Broken ramp',
    location: 'Bus NB-4521',
    status: ReportStatus.underReview,
    date: 'Aug 18',
  ),
  ConditionReport(
    title: 'Crowded station',
    location: 'Maradana Station',
    status: ReportStatus.verified,
    date: 'Aug 12',
  ),
  ConditionReport(
    title: 'Unsafe driving',
    location: 'Bus 177, route 100',
    status: ReportStatus.verified,
    date: 'Aug 3',
  ),
];

const mockVolunteerFeed = [
  ConditionReport(
    title: 'Lift out of service',
    location: 'Fort Station, Platform 2',
    status: ReportStatus.underReview,
    date: 'Today',
  ),
  ConditionReport(
    title: 'Crowded during peak hours',
    location: 'Bus 138',
    status: ReportStatus.verified,
    date: 'Yesterday',
  ),
  ConditionReport(
    title: 'Rest area unclean',
    location: 'Bambalapitiya Station',
    status: ReportStatus.underReview,
    date: 'Aug 18',
  ),
  ConditionReport(
    title: 'Tactile paving damaged',
    location: 'Maradana Station entrance',
    status: ReportStatus.verified,
    date: 'Aug 14',
  ),
];

const mockSharingHistory = [
  'Aug 19 — Shared with Nimal Perera, ended after 38 min',
  'Aug 15 — Shared with Kumari Silva, ended after 51 min',
];
