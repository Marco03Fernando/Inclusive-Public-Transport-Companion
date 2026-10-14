/// Which layer a condition-report operation failed in, so the UI (and the
/// debug log) can tell a Storage problem from a Firestore, auth, missing
/// index, validation or location problem.
enum ReportFailure {
  auth,
  validation,
  location,
  storage,
  firestore,
  missingIndex,
  network,
  unknown,
}

/// A condition-report failure with a message that can be shown to the user
/// as-is. [debugDetail] carries the raw Firebase code/message for logs.
class ReportException implements Exception {
  const ReportException(this.failure, this.message, {this.debugDetail});

  final ReportFailure failure;
  final String message;
  final String? debugDetail;

  @override
  String toString() => debugDetail == null
      ? '[${failure.name}] $message'
      : '[${failure.name}] $message ($debugDetail)';
}
