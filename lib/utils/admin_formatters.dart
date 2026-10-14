import '../models/condition_report.dart';

/// Display formatting shared by the admin screens and widgets.
/// (Plain Dart on purpose — no `intl` dependency needed.)
class AdminFormat {
  AdminFormat._();

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// e.g. "21 Sep 2026, 9:20 AM" (device local time).
  static String dateTime(DateTime value) {
    final dt = value.toLocal();
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}, $hour12:$minute $period';
  }

  /// "Bus", "Station", "Rest Area", "Other".
  static String subject(ReportSubject subject) {
    switch (subject) {
      case ReportSubject.bus:
        return 'Bus';
      case ReportSubject.station:
        return 'Station';
      case ReportSubject.restArea:
        return 'Rest Area';
      case ReportSubject.other:
        return 'Other';
    }
  }

  /// Vehicle or station number, or a placeholder when none was entered.
  static String vehicleNumber(ConditionReport report) {
    final value = report.vehicleOrStationNumber.trim();
    return value.isEmpty ? 'Not provided' : value;
  }

  /// Normalized route ID used for grouping, or "Unassigned" for legacy
  /// reports without route information.
  static String routeId(ConditionReport report) =>
      report.routeId.isEmpty ? BusRoute.unassignedLabel : report.routeId;

  /// Free-text location name, or a placeholder.
  static String locationName(ConditionReport report) {
    final value = report.location.label.trim();
    return value.isEmpty ? 'Not provided' : value;
  }

  /// "6.927100, 79.861200", or a placeholder when GPS wasn't captured.
  static String coordinates(ReportLocation location) {
    if (!location.hasCoordinates) return 'Not captured';
    return '${location.latitude!.toStringAsFixed(6)}, '
        '${location.longitude!.toStringAsFixed(6)}';
  }
}
