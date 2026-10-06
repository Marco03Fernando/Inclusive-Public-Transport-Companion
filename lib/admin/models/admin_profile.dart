/// The signed-in, VERIFIED admin.
///
/// An [AdminProfile] only ever exists after `admins/{uid}` was found in
/// Firestore — holding one means the account passed the admin check.
class AdminProfile {
  final String uid;
  final String? email;

  const AdminProfile({required this.uid, this.email});
}
