/// A failure in the admin module whose [message] is safe to show to the
/// admin as-is (e.g. in a SnackBar or an error banner).
///
/// Services and repositories throw this for expected problems (wrong
/// password, not an admin, report already reviewed). Anything else is
/// treated as unexpected and gets a generic message in the provider.
class AdminException implements Exception {
  final String message;

  const AdminException(this.message);

  @override
  String toString() => message;
}
