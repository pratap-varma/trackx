import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_latest;

class TimezoneService {
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    tz_latest.initializeTimeZones();
    _initialized = true;
  }

  /// Converts a UTC DateTime to a specific Timezone DateTime.
  static DateTime toTimezone(DateTime utcDateTime, String timezoneName) {
    initialize();
    try {
      final location = tz.getLocation(timezoneName);
      final tzDateTime = tz.TZDateTime.from(utcDateTime, location);
      return tzDateTime;
    } catch (_) {
      // Fallback to local
      return utcDateTime.toLocal();
    }
  }

  /// Returns the current DateTime in a specific Timezone.
  static DateTime nowInTimezone(String timezoneName) {
    initialize();
    try {
      final location = tz.getLocation(timezoneName);
      return tz.TZDateTime.now(location);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Safe comparison for midnight deadlines
  static bool isBeforeMidnight(DateTime checkTime, String timezoneName) {
    final tzNow = nowInTimezone(timezoneName);
    final tzMidnight = DateTime(tzNow.year, tzNow.month, tzNow.day, 23, 59, 59);
    return checkTime.isBefore(tzMidnight);
  }
}
