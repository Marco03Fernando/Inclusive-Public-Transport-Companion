import 'package:cloud_firestore/cloud_firestore.dart';

enum AssistanceType { boarding, guidance, other }

enum AssistanceStatus { pending, accepted, completed, cancelled }

const assistanceTypeLabelKeys = {
  AssistanceType.boarding: 'requestTypeBoarding',
  AssistanceType.guidance: 'requestTypeGuidance',
  AssistanceType.other: 'requestTypeOther',
};

const assistanceStatusLabelKeys = {
  AssistanceStatus.pending: 'requestStatusPending',
  AssistanceStatus.accepted: 'requestStatusAccepted',
  AssistanceStatus.completed: 'requestStatusCompleted',
  AssistanceStatus.cancelled: 'requestStatusCancelled',
};

class AssistanceRequest {
  const AssistanceRequest({
    required this.id,
    required this.passengerUid,
    required this.passengerName,
    required this.type,
    this.note,
    required this.status,
    this.volunteerUid,
    this.volunteerName,
    this.lat,
    this.lng,
    this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  final String id;
  final String passengerUid;
  final String passengerName;
  final AssistanceType type;
  final String? note;
  final AssistanceStatus status;
  final String? volunteerUid;
  final String? volunteerName;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  Map<String, dynamic> toCreateMap() => {
        'passengerUid': passengerUid,
        'passengerName': passengerName,
        'type': type.name,
        'note': note,
        'status': AssistanceStatus.pending.name,
        'volunteerUid': null,
        'volunteerName': null,
        'lat': lat,
        'lng': lng,
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'completedAt': null,
      };

  factory AssistanceRequest.fromMap(String id, Map<String, dynamic> map) => AssistanceRequest(
        id: id,
        passengerUid: map['passengerUid'] as String? ?? '',
        passengerName: map['passengerName'] as String? ?? '',
        type: AssistanceType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => AssistanceType.other,
        ),
        note: map['note'] as String?,
        status: AssistanceStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => AssistanceStatus.pending,
        ),
        volunteerUid: map['volunteerUid'] as String?,
        volunteerName: map['volunteerName'] as String?,
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
        completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      );
}
