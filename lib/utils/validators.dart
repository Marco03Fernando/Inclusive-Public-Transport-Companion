import '../models/report_model.dart';

/// Form-field validators for the Condition Reporting flow. Pure
/// functions so they're easy to unit test independent of any widget.
class ReportValidators {
  ReportValidators._();

  static String? subject(ReportSubject? value) {
    if (value == null) return 'Choose what you are reporting.';
    return null;
  }

  static String? conditionType(ConditionType? value) {
    if (value == null) return 'Choose a condition type.';
    return null;
  }

  static String? vehicleOrStationNumber(String? value, ReportSubject? subject) {
    if (subject == ReportSubject.other) return null; // optional for "Other"
    if (value == null || value.trim().isEmpty) {
      return 'Enter a vehicle or station number.';
    }
    if (value.trim().length < 2) {
      return 'That number looks too short — please check it.';
    }
    return null;
  }

  static String? location(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Add a location using the GPS button.';
    }
    return null;
  }

  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe what you saw.';
    }
    if (value.trim().length < 10) {
      return 'Please add a few more details (at least 10 characters).';
    }
    return null;
  }
}
