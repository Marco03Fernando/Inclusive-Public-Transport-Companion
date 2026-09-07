import 'report_model.dart';

export 'report_model.dart';

/// Record of an admin's review decision on a report. Kept as its own
/// small class so a report can be created with `adminVerification: null`
/// today and have this filled in later by an admin panel / backend
/// webhook without changing the [ConditionReport] shape.
class AdminVerification {
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? notes;

  const AdminVerification({this.verifiedBy, this.verifiedAt, this.notes});

  Map<String, dynamic> toJson() => {
        'verifiedBy': verifiedBy,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'notes': notes,
      };

  factory AdminVerification.fromJson(Map<String, dynamic> json) => AdminVerification(
        verifiedBy: json['verifiedBy'] as String?,
        verifiedAt: json['verifiedAt'] == null
            ? null
            : DateTime.tryParse(json['verifiedAt'] as String),
        notes: json['notes'] as String?,
      );
}

/// A finalized, submitted condition report.
///
/// This is the model that leaves the device: [ConditionReportService]
/// and the repository layer pass this around, and [toJson]/[fromJson]
/// define the exact wire format for a future REST API or Firestore
/// document — see the class-level doc in `condition_report_repository.dart`
/// for the intended backend shape.
class ConditionReport {
  final String id;
  final ReportSubject subject;
  final String vehicleOrStationNumber;
  final ReportLocation location;
  final ConditionType conditionType;
  final String description;
  final String? photoPath;
  final DateTime submittedAt;
  final ReportStatus status;
  final AdminVerification? adminVerification;

  const ConditionReport({
    required this.id,
    required this.subject,
    required this.vehicleOrStationNumber,
    required this.location,
    required this.conditionType,
    required this.description,
    this.photoPath,
    required this.submittedAt,
    this.status = ReportStatus.underReview,
    this.adminVerification,
  });

  /// Short title line used on the "My Reports" cards, e.g. "Bus NB-1234".
  String get title {
    final subjectLabel = _titleCase(subject.label);
    if (vehicleOrStationNumber.trim().isEmpty) return subjectLabel;
    return '$subjectLabel ${vehicleOrStationNumber.trim()}';
  }

  /// Human-friendly "Submitted ..." line used on the "My Reports" cards.
  String get submittedLabel {
    final now = DateTime.now();
    final isToday = now.year == submittedAt.year &&
        now.month == submittedAt.month &&
        now.day == submittedAt.day;
    if (isToday) {
      return 'Submitted today, ${_formatTime(submittedAt)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == submittedAt.year &&
        yesterday.month == submittedAt.month &&
        yesterday.day == submittedAt.day;
    if (isYesterday) return 'Submitted yesterday';

    final days = now.difference(submittedAt).inDays;
    return 'Submitted $days day${days == 1 ? '' : 's'} ago';
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0] + s.substring(1).toLowerCase();
  }

  static String _formatTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  /// Builds a submittable [ConditionReport] from a completed
  /// [ConditionReportDraft]. Assumes Step 1 already guaranteed [subject]
  /// and [conditionType] are set (form validation enforces this).
  factory ConditionReport.fromDraft(ConditionReportDraft draft) {
    assert(draft.subject != null, 'Draft must have a subject before submitting.');
    assert(draft.conditionType != null, 'Draft must have a condition type before submitting.');
    return ConditionReport(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      subject: draft.subject!,
      vehicleOrStationNumber: draft.vehicleOrStationNumber.trim(),
      location: draft.reportLocation ??
          ReportLocation(
            label: draft.location.trim().isEmpty ? 'Not provided' : draft.location.trim(),
          ),
      conditionType: draft.conditionType!,
      description: draft.description.trim(),
      photoPath: draft.photoPath,
      submittedAt: DateTime.now(),
      status: ReportStatus.underReview,
    );
  }

  ConditionReport copyWith({
    ReportStatus? status,
    AdminVerification? adminVerification,
  }) {
    return ConditionReport(
      id: id,
      subject: subject,
      vehicleOrStationNumber: vehicleOrStationNumber,
      location: location,
      conditionType: conditionType,
      description: description,
      photoPath: photoPath,
      submittedAt: submittedAt,
      status: status ?? this.status,
      adminVerification: adminVerification ?? this.adminVerification,
    );
  }

  /// JSON shape designed to map 1:1 onto a future REST/Firestore document:
  /// ```json
  /// {
  ///   "id": "1735300000000000",
  ///   "subject": "bus",
  ///   "vehicleOrStationNumber": "NB-1234",
  ///   "location": { "latitude": 6.9271, "longitude": 79.8612, "label": "Current location attached" },
  ///   "conditionType": "brokenRamp",
  ///   "description": "Ramp is bent and won't lower.",
  ///   "photoPath": "/data/.../report_photo.jpg",
  ///   "submittedAt": "2026-08-28T09:20:00.000",
  ///   "status": "underReview",
  ///   "adminVerification": null
  /// }
  /// ```
  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject.name,
        'vehicleOrStationNumber': vehicleOrStationNumber,
        'location': location.toJson(),
        'conditionType': conditionType.name,
        'description': description,
        'photoPath': photoPath,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.name,
        'adminVerification': adminVerification?.toJson(),
      };

  factory ConditionReport.fromJson(Map<String, dynamic> json) => ConditionReport(
        id: json['id'] as String,
        subject: ReportSubject.values.byName(json['subject'] as String),
        vehicleOrStationNumber: json['vehicleOrStationNumber'] as String? ?? '',
        location: json['location'] == null
            ? ReportLocation.empty
            : ReportLocation.fromJson(json['location'] as Map<String, dynamic>),
        conditionType: ConditionType.values.byName(json['conditionType'] as String),
        description: json['description'] as String? ?? '',
        photoPath: json['photoPath'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        status: ReportStatus.values.byName(json['status'] as String? ?? 'underReview'),
        adminVerification: json['adminVerification'] == null
            ? null
            : AdminVerification.fromJson(json['adminVerification'] as Map<String, dynamic>),
      );
}
