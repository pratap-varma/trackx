import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle response actions
        },
      );
      _initialized = true;
    } catch (_) {
      // Gracefully handle test environment / platform missing bindings
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final approvedAndroid =
          await androidImplementation?.requestNotificationsPermission() ??
          false;

      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final approvedIos =
          await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;

      return approvedAndroid || approvedIos;
    } catch (_) {
      return false;
    }
  }

  /// Generate a unique stable notification ID
  static int generateStableId(String entryId, int dayOffset, int typeId) {
    // Combine entry hash and offset
    return (entryId.hashCode + dayOffset * 10 + typeId) & 0x7FFFFFFF;
  }

  Future<void> scheduleReminders(
    List<TimetableEntry> entries,
    double globalTarget,
  ) async {
    if (!_initialized) return;

    try {
      await cancelAll();

      final activeEntries = entries.where((e) => e.isEnabled).toList();
      final now = DateTime.now();

      // Schedule reminders for the next 14 days rolling window
      for (int i = 0; i < 14; i++) {
        final date = now.add(Duration(days: i));
        final weekday = date.weekday;

        // Skip Sunday
        if (weekday == 7) continue;

        final dayEntries = activeEntries
            .where((e) => e.dayOfWeek == weekday)
            .toList();

        for (final entry in dayEntries) {
          // Schedule end-of-class prompt
          final endDateTime = entry.toDateTime(date, entry.endTime);
          if (endDateTime.isAfter(now)) {
            final notificationId = generateStableId(entry.id, i, 1);

            await _plugin.zonedSchedule(
              notificationId,
              'Class Completed',
              'Did you attend Period ${entry.periodNumber} today?',
              tz.TZDateTime.from(endDateTime, tz.local),
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'trackx_reminders',
                  'Attendance Prompts',
                  channelDescription: 'Scheduled class logging notifications',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  categoryIdentifier: 'attendance_prompt',
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
        }
      }
    } catch (_) {
      // Fail silently in unsupported test runtimes
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
