import 'condition_report.dart';

export 'condition_report.dart';

/// The privacy-safe, read-only copy of an accepted condition report that
/// appears in Community Reports (`public_condition_reports/{reportId}`).
///
/// It holds ONLY whitelisted fields (see [PublicReportFields]) — never the
/// reporter's UID, email, phone, exact GPS position, admin comment or
/// audit fields. Admins publish it (see `firestore.rules`), and only for
/// reports whose reporter opted in with [ReportFields.shareWithCommunity].
class PublicConditionReport {
  const PublicConditionReport({
    required this.id,
    required this.reportType,
    required this.routeNumber,
    required this.subject,
    required this.vehicleOrStationNumber,
    required this.conditionType,
    required this.description,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.contributorName,
    required this.status,
    required this.createdAt,
  });

  /// Same ID as the private `condition_reports` document.
  final String id;
  final ReportType reportType;
  final String routeNumber;
  final ReportSubject subject;
  final String vehicleOrStationNumber;
  final ConditionType conditionType;
  final String description;
  final String locationName;

  /// Rounded to 3 decimal places (≈100 m) when published, so the
  /// reporter's exact position is never shared.
  final double? latitude;
  final double? longitude;

  final String? photoUrl;

  /// The name the reporter chose to show, or null for anonymous.
  final String? contributorName;

  /// Always accepted (or the legacy "verified") — nothing else is published.
  final ReportStatus status;
  final DateTime createdAt;

  /// "Bus NB-1234" / "Station Fort" / "Rest area".
  String get title {
    final label = subject.label;
    final subjectTitle = label[0] + label.substring(1).toLowerCase();
    final reference = vehicleOrStationNumber.trim();
    return reference.isEmpty ? subjectTitle : '$subjectTitle $reference';
  }

  /// Card / details heading, e.g. "Bus NB-1234 · Broken ramp".
  String get headline => '$title · ${conditionType.sentenceCase}';

  String? get routeLabel =>
      routeNumber.trim().isEmpty ? null : routeNumber.trim();

  bool get hasApproximatePosition => latitude != null && longitude != null;

  /// The location to show: the stored label, unless it is only the form's
  /// generic "Current location attached" marker, in which case the
  /// approximate coordinates are clearer.
  String get locationLabel {
    final label = locationName.trim();
    final generic = label.isEmpty || label == _gpsPlaceholder;
    if (generic && hasApproximatePosition) {
      return 'Near ${latitude!.toStringAsFixed(3)}, '
          '${longitude!.toStringAsFixed(3)}';
    }
    return label.isEmpty ? 'Location not provided' : label;
  }

  /// What `LocationService` labels a GPS fix with.
  static const _gpsPlaceholder = 'Current location attached';

  String get submittedLabel => submittedLabelFor(createdAt);

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
}

/// Firestore names for the public projection — the single source of truth
/// shared by the community feed (read) and the admin publisher (write), and
/// mirrored by the field whitelist in `firestore.rules`.
abstract final class PublicReportFields {
  static const collection = 'public_condition_reports';

  static const reportType = ReportFields.reportType;
  static const routeNumber = ReportFields.routeNumber;
  static const routeId = ReportFields.routeId;
  static const subject = 'subject';
  static const vehicleOrStationNumber = 'vehicleOrStationNumber';
  static const conditionType = 'conditionType';
  static const description = 'description';
  static const locationName = 'locationName';
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const photoUrl = 'photoUrl';

  /// Copied from the private report's [ReportFields.publicDisplayName].
  static const contributorName = 'contributorName';
  static const status = ReportFields.status;
  static const createdAt = 'createdAt';
  static const publishedAt = 'publishedAt';
}
