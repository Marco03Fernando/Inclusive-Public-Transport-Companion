import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/state/app_state.dart';
import 'access_need.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.dob,
    required this.accessNeeds,
    required this.isAnonymous,
    this.createdAt,
  });

  final String uid;
  final AppRole role;
  final String name;
  final String phone;
  final String dob;
  final List<AccessNeed> accessNeeds;
  final bool isAnonymous;
  final DateTime? createdAt;

  /// Up to two initials from [name] (e.g. "Kamala Fernando" -> "KF"),
  /// falling back to "?" for a blank name.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p[0].toUpperCase());
    return letters.join();
  }

  Map<String, dynamic> toMap() => {
        'role': role == AppRole.passenger ? 'passenger' : 'volunteer',
        'name': name,
        'phone': phone,
        'dob': dob,
        'accessNeeds': accessNeeds.map((n) => {'id': n.id, 'checked': n.checked}).toList(),
        'isAnonymous': isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Rehydrates access needs against [defaults] so labels/order stay defined
  /// client-side (see lib/data/mock_data.dart) — Firestore only stores which
  /// ids are checked, never the label key.
  factory UserProfile.fromMap(String uid, Map<String, dynamic> map, List<AccessNeed> defaults) {
    final checkedIds = <String>{};
    for (final entry in (map['accessNeeds'] as List<dynamic>? ?? const [])) {
      final entryMap = entry as Map<String, dynamic>;
      if (entryMap['checked'] == true) checkedIds.add(entryMap['id'] as String);
    }
    return UserProfile(
      uid: uid,
      role: map['role'] == 'volunteer' ? AppRole.volunteer : AppRole.passenger,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      accessNeeds: defaults.map((n) => n.copyWith(checked: checkedIds.contains(n.id))).toList(),
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
