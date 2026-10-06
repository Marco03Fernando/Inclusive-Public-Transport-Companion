/// Role stored in `users/{uid}.role`.
///
/// Normal users get [UserRole.user] automatically when they register.
/// [UserRole.admin] is only ever set by hand in the Firebase console —
/// the Firestore security rules stop anyone from giving themselves a role.
enum UserRole { user, admin }

/// The Firestore profile document at `users/{uid}`:
///
/// ```json
/// { "name": "...", "email": "...", "role": "user" | "admin" }
/// ```
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role.name,
      };

  /// Anything other than exactly "admin" is treated as a normal user, so a
  /// missing or mistyped role can never grant admin access.
  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] == UserRole.admin.name ? UserRole.admin : UserRole.user,
    );
  }
}
