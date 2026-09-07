/// Base data models for the Condition Reporting feature.
///
/// [ConditionReport] (in `condition_report.dart`) is the finalized,
/// JSON-serializable model used once a report is submitted — it imports
/// and re-exports everything in this file, so most other files only need
/// to import `condition_report.dart`.

/// What kind of thing is being reported on.
enum ReportSubject { bus, station, restArea, other }

/// The type of accessibility problem being reported.
enum ConditionType { brokenRamp, noSeat, overcrowded, unsafe }

/// Review status shown on the "My Reports" screen and used by admin
/// verification handling.
enum ReportStatus { underReview, verified }

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
  ReportSubject? subject;
  String vehicleOrStationNumber;
  String location;
  ReportLocation? reportLocation;
  ConditionType? conditionType;
  String description;
  String? photoPath;

  ConditionReportDraft({
    this.subject,
    this.vehicleOrStationNumber = '',
    this.location = '',
    this.reportLocation,
    this.conditionType,
    this.description = '',
    this.photoPath,
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
