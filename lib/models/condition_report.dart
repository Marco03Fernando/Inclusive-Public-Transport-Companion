import 'report_model.dart';

export 'report_model.dart';

/// A finalized condition report.
///
/// This is the model that leaves the device: [ConditionReportService]
/// and the repository layer pass this around. [toJson]/[fromJson] are a
/// generic wire format used by the local/REST repositories; the
/// Firestore-specific document shape (flat `locationName`/`latitude`/
/// `longitude`, `photoUrl`, etc.) is handled inside
/// `firebase_condition_report_repository.dart` so this model stays free
/// of any Firebase dependency.
class ConditionReport {
  /// Firestore document ID (called `reportId` in the document itself).
  /// Empty until the repository has actually persisted the report.
  final String id;

  /// UID of the user who submitted this report. Assigned by
  /// [ReportsProvider] from [AuthService.currentUserId] before the report
  /// reaches the repository — screens never need to know about it.
  final String userId;

  final ReportSubject subject;
  final String vehicleOrStationNumber;
  final ReportLocation location;
  final ConditionType conditionType;
  final String description;

  /// Local on-device file path from the image picker, before upload.
  /// Transient — never persisted. Null once there's no local file (e.g.
  /// after loading a report back down from Firestore).
  final String? photoPath;

  /// Public download URL once the photo has been uploaded to Firebase
  /// Storage. This is what gets persisted and displayed.
  final String? photoUrl;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final ReportStatus status;

  /// Free-text note an admin can attach when reviewing a report.
  final String? adminComment;

  const ConditionReport({
    required this.id,
    this.userId = '',
    required this.subject,
    required this.vehicleOrStationNumber,
    required this.location,
    required this.conditionType,
    required this.description,
    this.photoPath,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
    this.status = ReportStatus.underReview,
    this.adminComment,
  });

  /// Short title line used on the "My Reports" cards, e.g. "Bus NB-1234".
  String get title {
    final subjectLabel = _titleCase(subject.label);
    if (vehicleOrStationNumber.trim().isEmpty) return subjectLabel;
    return '$subjectLabel ${vehicleOrStationNumber.trim()}';
  }

  /// Human-friendly "Submitted ..." line used on the "My Reports" cards,
  /// e.g. "Submitted today, 9:20 AM".
  String get submittedLabel {
    final now = DateTime.now();
    final isToday = now.year == createdAt.year &&
        now.month == createdAt.month &&
        now.day == createdAt.day;
    if (isToday) {
      return 'Submitted today, ${_formatTime(createdAt)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == createdAt.year &&
        yesterday.month == createdAt.month &&
        yesterday.day == createdAt.day;
    if (isYesterday) return 'Submitted yesterday';

    final days = now.difference(createdAt).inDays;
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
  ///
  /// [id] and [userId] are left empty/blank here — the repository
  /// assigns the real Firestore document ID, and [ReportsProvider] fills
  /// in [userId] from the signed-in user right before submission.
  factory ConditionReport.fromDraft(ConditionReportDraft draft) {
    assert(draft.subject != null, 'Draft must have a subject before submitting.');
    assert(draft.conditionType != null, 'Draft must have a condition type before submitting.');
    return ConditionReport(
      id: '',
      subject: draft.subject!,
      vehicleOrStationNumber: draft.vehicleOrStationNumber.trim(),
      location: draft.reportLocation ??
          ReportLocation(
            label: draft.location.trim().isEmpty ? 'Not provided' : draft.location.trim(),
          ),
      conditionType: draft.conditionType!,
      description: draft.description.trim(),
      photoPath: draft.photoPath,
      createdAt: DateTime.now(),
      status: ReportStatus.underReview,
    );
  }

  ConditionReport copyWith({
    String? id,
    String? userId,
    String? photoPath,
    String? photoUrl,
    DateTime? updatedAt,
    ReportStatus? status,
    String? adminComment,
  }) {
    return ConditionReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject,
      vehicleOrStationNumber: vehicleOrStationNumber,
      location: location,
      conditionType: conditionType,
      description: description,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      adminComment: adminComment ?? this.adminComment,
    );
  }

  /// Generic JSON shape used by the local (SharedPreferences) and REST
  /// repositories. Not used by the Firestore repository — see
  /// `firebase_condition_report_repository.dart` for that mapping.
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'subject': subject.name,
        'vehicleOrStationNumber': vehicleOrStationNumber,
        'location': location.toJson(),
        'conditionType': conditionType.name,
        'description': description,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'status': status.name,
        'adminComment': adminComment,
      };

  factory ConditionReport.fromJson(Map<String, dynamic> json) => ConditionReport(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        subject: ReportSubject.values.byName(json['subject'] as String),
        vehicleOrStationNumber: json['vehicleOrStationNumber'] as String? ?? '',
        location: json['location'] == null
            ? ReportLocation.empty
            : ReportLocation.fromJson(json['location'] as Map<String, dynamic>),
        conditionType: ConditionType.values.byName(json['conditionType'] as String),
        description: json['description'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] == null ? null : DateTime.tryParse(json['updatedAt'] as String),
        status: ReportStatus.values.byName(json['status'] as String? ?? 'underReview'),
        adminComment: json['adminComment'] as String?,
      );
}
