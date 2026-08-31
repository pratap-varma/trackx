import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/notifications/domain/daily_digest_model.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/timetable/providers/timetable_provider.dart';

class DailyDigestService {
  static const String _keySettings = 'pref_daily_digest_settings_v1';
  static const int dailyDigestNotificationId = 8888;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final SharedPreferences _prefs;
  bool _initialized = false;

  DailyDigestService(this._prefs);

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
          // Payload '/dashboard' is handled by deep link / router
        },
      );
      _initialized = true;
    } catch (_) {
      // Gracefully handle test environment / missing platform bindings
    }
  }

  DailyDigestSettings getSettings() {
    final jsonStr = _prefs.getString(_keySettings);
    if (jsonStr == null) return const DailyDigestSettings();
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DailyDigestSettings.fromMap(map);
    } catch (_) {
      return const DailyDigestSettings();
    }
  }

  Future<void> saveSettings(DailyDigestSettings settings) async {
    await _prefs.setString(_keySettings, jsonEncode(settings.toMap()));
  }

  Future<void> scheduleDailyDigest({
    required DailyDigestSettings settings,
    required DailyDigestMessage message,
  }) async {
    await initialize();

    try {
      await _plugin.cancel(dailyDigestNotificationId);

      if (!settings.enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        settings.hour,
        settings.minute,
      );

      // If scheduled time has already passed today, advance to tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'trackx_daily_digest',
          'Daily Digest Briefing',
          channelDescription: 'Daily morning attendance and schedule summary',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'daily_digest',
        ),
      );

      await _plugin.zonedSchedule(
        dailyDigestNotificationId,
        message.title,
        message.body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/dashboard',
      );
    } catch (_) {
      // Gracefully handle unsupported testing environments
    }
  }

  Future<void> triggerInstantTestNotification(
      DailyDigestMessage message) async {
    await initialize();

    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'trackx_daily_digest',
          'Daily Digest Briefing',
          channelDescription: 'Daily morning attendance and schedule summary',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'daily_digest',
        ),
      );

      await _plugin.show(
        dailyDigestNotificationId + 1, // distinct test ID
        message.title,
        message.body,
        notificationDetails,
        payload: '/dashboard',
      );
    } catch (_) {
      // Silently catch in unit tests
    }
  }

  Future<void> cancelDailyDigest() async {
    try {
      await _plugin.cancel(dailyDigestNotificationId);
    } catch (_) {}
  }
}

final dailyDigestServiceProvider = Provider<DailyDigestService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DailyDigestService(prefs);
});

// Composed Current Daily Digest Message Provider
final currentDailyDigestMessageProvider =
    Provider<DailyDigestMessage>((ref) {
  final todayClasses = ref.watch(todayTimetableProvider);
  final semesterStats = ref.watch(statsProvider);
  final allTasks = ref.watch(tasksProvider);
  final allExams = ref.watch(examsProvider);
  final subjects = ref.watch(subjectRepositoryProvider);

  return DailyDigestComposer.compose(
    todayClasses: todayClasses,
    allSubjectStats: semesterStats.allSubjectStats,
    todayTasks: allTasks,
    upcomingExams: allExams,
    hasSubjectsConfigured: subjects.isNotEmpty,
  );
});

// Settings StateNotifier Provider
class DailyDigestSettingsNotifier extends StateNotifier<DailyDigestSettings> {
  final DailyDigestService _service;
  final Ref _ref;

  DailyDigestSettingsNotifier(this._service, this._ref)
      : super(_service.getSettings()) {
    // Re-schedule on startup with fresh data
    _reschedule();
  }

  Future<void> updateSettings(DailyDigestSettings newSettings) async {
    state = newSettings;
    await _service.saveSettings(newSettings);
    await _reschedule();
  }

  Future<void> toggleEnabled(bool enabled) async {
    await updateSettings(state.copyWith(enabled: enabled));
  }

  Future<void> setDeliveryTime(int hour, int minute) async {
    await updateSettings(state.copyWith(hour: hour, minute: minute));
  }

  Future<void> triggerTestPreview() async {
    final message = _ref.read(currentDailyDigestMessageProvider);
    await _service.triggerInstantTestNotification(message);
  }

  Future<void> _reschedule() async {
    final message = _ref.read(currentDailyDigestMessageProvider);
    await _service.scheduleDailyDigest(
      settings: state,
      message: message,
    );
  }
}

final dailyDigestSettingsProvider =
    StateNotifierProvider<DailyDigestSettingsNotifier, DailyDigestSettings>(
        (ref) {
  final service = ref.watch(dailyDigestServiceProvider);
  return DailyDigestSettingsNotifier(service, ref);
});
