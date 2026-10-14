/// Base data models for the Condition Reporting feature.
///
/// [ConditionReport] (in `condition_report.dart`) is the finalized,
/// JSON-serializable model used once a report is submitted — it imports
/// and re-exports everything in this file, so most other files only need
/// to import `condition_report.dart`.
library;

/// What kind of thing is being reported on.
enum ReportSubject { bus, station, restArea, other }

/// The type of accessibility problem being reported. Stored in Firestore
/// by [Enum.name], so existing values must never be renamed.
enum ConditionType { brokenRamp, noSeat, overcrowded, unsafe, unclean, other }

/// Review status shown on the "My Reports" screen and used by admin
/// verification handling.
enum ReportStatus { underReview, verified, accepted, rejected }

/// Whether a report confirms an accessibility feature is present and
/// working ([positive]) or reports it missing/damaged/broken ([issue]).
/// Stored in Firestore by [Enum.name] (`"positive"` / `"issue"`), so
/// existing values must never be renamed.
///
/// [unknown] is never written by the app — it is what reports submitted
/// before this field existed (or with an unrecognised value) read back
/// as, so legacy data is never guessed into a real classification.
enum ReportType {
  positive,
  issue,
  unknown;

  /// Reads a stored `reportType` value; anything missing or unrecognised
  /// becomes [unknown].
  static ReportType parse(Object? raw) {
    if (raw == positive.name) return positive;
    if (raw == issue.name) return issue;
    return unknown;
  }

  /// The values a user can choose on the report form.
  static const selectable = [positive, issue];
}

extension ReportTypeLabel on ReportType {
  /// Professional label shown wherever a report is displayed.
  String get label {
    switch (this) {
      case ReportType.positive:
        return 'Positive Accessibility Feedback';
      case ReportType.issue:
        return 'Accessibility Issue';
      case ReportType.unknown:
        return 'Unclassified';
    }
  }

  /// `context.t` key for the report form's "Report Type" dropdown.
  String get labelKey {
    switch (this) {
      case ReportType.positive:
        return 'reportTypePositive';
      case ReportType.issue:
        return 'reportTypeIssue';
      case ReportType.unknown:
        return 'reportTypeUnknown';
    }
  }

  /// `context.t` key for the one-line explanation under the dropdown.
  String get descriptionKey {
    switch (this) {
      case ReportType.positive:
        return 'reportTypePositiveDesc';
      case ReportType.issue:
        return 'reportTypeIssueDesc';
      case ReportType.unknown:
        return 'reportTypeUnknownDesc';
    }
  }

  bool get isClassified => this != ReportType.unknown;
}

/// Bus route identifiers as entered by users ("138", "177", "138A",
/// "EX1-1") and their normalized form used for grouping.
///
/// - `routeNumber` keeps what the user typed (trimmed, inner whitespace
///   collapsed) for display.
/// - `routeId` is [normalize]d — upper-case, no whitespace — so "138a",
///   " 138 A " and "138A" all group under `"138A"`.
class BusRoute {
  BusRoute._();

  static const int maxLength = 12;

  /// Shown wherever a report has no route (legacy reports).
  static const String unassignedLabel = 'Unassigned';

  static final _whitespace = RegExp(r'\s+');

  /// Letters/digits, optionally split by single "-" or "/" separators.
  static final _validId = RegExp(r'^[A-Z0-9]+([/-][A-Z0-9]+)*$');
  static final _digit = RegExp(r'[0-9]');

  /// User-facing value: trimmed, inner whitespace collapsed to one space.
  static String displayValue(String raw) =>
      raw.trim().replaceAll(_whitespace, ' ');

  /// Grouping key: all whitespace removed, upper-cased.
  static String normalize(String raw) =>
      raw.replaceAll(_whitespace, '').toUpperCase();

  /// Null when [raw] is a usable route number, otherwise why it isn't.
  static String? validate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Enter the bus route number (e.g. 138 or 138A).';
    }
    final id = normalize(raw);
    if (id.length > maxLength) {
      return 'That route number is too long — please check it.';
    }
    if (!_validId.hasMatch(id)) {
      return 'Use only letters, numbers, "-" or "/" (e.g. 138 or 138A).';
    }
    if (!_digit.hasMatch(id)) {
      return 'A bus route number must include a number (e.g. 138).';
    }
    return null;
  }

  static bool isValid(String? raw) => validate(raw) == null;
}

/// Firestore field names in `condition_reports` for the route-based
/// accessibility data, shared by every repository (and by the future
/// points system) so the names can never drift apart.
abstract final class ReportFields {
  /// `"positive"` | `"issue"` ([ReportType.name]). Absent on legacy docs.
  static const reportType = 'reportType';

  /// Route as entered, e.g. `"138A"`. Absent on legacy docs.
  static const routeNumber = 'routeNumber';

  /// [BusRoute.normalize]d route, e.g. `"138A"`. Group/query by this.
  static const routeId = 'routeId';

  static const status = 'status';

  /// The reporter's explicit opt-in (set once, at submission) to have the
  /// report shown in Community Reports after an admin accepts it. Absent
  /// on legacy docs, which therefore can never be published.
  static const shareWithCommunity = 'shareWithCommunity';

  /// The name the reporter chose to show on the community copy (their
  /// profile name at submission time), or null to appear anonymously.
  static const publicDisplayName = 'publicDisplayName';
}

extension ReportSubjectLabel on ReportSubject {
  String get label {
    switch (this) {
      case ReportSubject.bus:
        return 'BUS';
      case ReportSubject.station:
        return 'STATION';
      case ReportSubject.restArea:
        return 'REST AREA';
      case ReportSubject.other:
        return 'OTHER';
    }
  }

  /// `context.t` key for the report form's "What are you reporting?" chips.
  String get labelKey {
    switch (this) {
      case ReportSubject.bus:
        return 'targetBus';
      case ReportSubject.station:
        return 'targetStation';
      case ReportSubject.restArea:
        return 'targetRest';
      case ReportSubject.other:
        return 'targetOther';
    }
  }
}

extension ReportStatusLabel on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.underReview:
        return 'UNDER REVIEW';
      case ReportStatus.verified:
        return 'VERIFIED';
      case ReportStatus.accepted:
        return 'ACCEPTED';
      case ReportStatus.rejected:
        return 'REJECTED';
    }
  }

  /// `context.t` key for the localized status pill — doubles as [name].
  String get labelKey => name;
}

extension ConditionTypeLabel on ConditionType {
  String get label {
    switch (this) {
      case ConditionType.brokenRamp:
        return 'BROKEN RAMP';
      case ConditionType.noSeat:
        return 'NO SEAT';
      case ConditionType.overcrowded:
        return 'OVERCROWDED';
      case ConditionType.unsafe:
        return 'UNSAFE';
      case ConditionType.unclean:
        return 'UNCLEAN';
      case ConditionType.other:
        return 'OTHER';
    }
  }

  /// Human readable version used in the summary card, e.g. "Broken ramp".
  String get sentenceCase {
    switch (this) {
      case ConditionType.brokenRamp:
        return 'Broken ramp';
      case ConditionType.noSeat:
        return 'No seat';
      case ConditionType.overcrowded:
        return 'Overcrowded';
      case ConditionType.unsafe:
        return 'Unsafe';
      case ConditionType.unclean:
        return 'Unclean';
      case ConditionType.other:
        return 'Other';
    }
  }

  /// `context.t` key for the report form's "Condition type" chips.
  String get labelKey {
    switch (this) {
      case ConditionType.brokenRamp:
        return 'condLift';
      case ConditionType.noSeat:
        return 'condNoSeat';
      case ConditionType.overcrowded:
        return 'condCrowded';
      case ConditionType.unsafe:
        return 'condUnsafe';
      case ConditionType.unclean:
        return 'condClean';
      case ConditionType.other:
        return 'condOther';
    }
  }
}

/// Geographic location captured for a report. A report can still be
/// submitted with just a free-text label (e.g. if GPS is unavailable),
/// so [latitude]/[longitude] are nullable.
class ReportLocation {
  final double? latitude;
  final double? longitude;
  final String label;

  const ReportLocation({this.latitude, this.longitude, this.label = ''});

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'label': label,
  };

  factory ReportLocation.fromJson(Map<String, dynamic> json) => ReportLocation(
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    label: json['label'] as String? ?? '',
  );

  static const empty = ReportLocation();
}

/// Everything collected across Step 1 and Step 2 of the report flow,
/// before it becomes a submitted [ConditionReport].
class ConditionReportDraft {
  /// Null until the user picks one — the form never preselects a type.
  ReportType? reportType;

  /// Bus route as typed; normalized when the report is built.
  String routeNumber;
  ReportSubject? subject;
  String vehicleOrStationNumber;
  String location;
  ReportLocation? reportLocation;
  ConditionType? conditionType;
  String description;
  String? photoPath;

  /// Opt-in to Community Reports once verified. Off unless the user turns
  /// it on.
  bool shareWithCommunity;

  /// Name to show publicly (profile name), or null for anonymous. Ignored
  /// unless [shareWithCommunity] is on.
  String? publicDisplayName;

  ConditionReportDraft({
    this.reportType,
    this.routeNumber = '',
    this.subject,
    this.vehicleOrStationNumber = '',
    this.location = '',
    this.reportLocation,
    this.conditionType,
    this.description = '',
    this.photoPath,
    this.shareWithCommunity = false,
    this.publicDisplayName,
  });

  /// Short title line used in the summary card, e.g. "Bus NB-1234".
  String get summaryTitle {
    final subjectLabel = subject == null ? '' : _titleCase(subject!.label);
    if (vehicleOrStationNumber.trim().isEmpty) return subjectLabel;
    return '$subjectLabel ${vehicleOrStationNumber.trim()}';
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0] + s.substring(1).toLowerCase();
  }
}
