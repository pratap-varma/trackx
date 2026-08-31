import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:trackx/features/planner/domain/models/productivity_models.dart';

class ExamNotificationService {
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
          // Deep link payload handled if needed
        },
      );
      _initialized = true;
    } catch (_) {
      // Gracefully handle test environment / missing platform bindings
    }
  }

  /// Request runtime notification permissions on Android 13+ & iOS
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

  /// Generate a unique stable notification ID for exam reminders
  static int generateExamNotificationId(String examId, int typeOffset) {
    return (examId.hashCode + typeOffset * 1000) & 0x7FFFFFFF;
  }

  /// Schedule notifications for all upcoming exams
  Future<void> scheduleExamReminders(List<Exam> exams) async {
    await initialize();

    try {
      final now = DateTime.now();
      final upcoming = exams.where((e) => e.examDate.isAfter(now)).toList();

      for (final exam in upcoming) {
        // 1. Reminder 1 day before exam at 6:00 PM
        final oneDayBefore = DateTime(
          exam.examDate.year,
          exam.examDate.month,
          exam.examDate.day - 1,
          18,
          0,
        );

        if (oneDayBefore.isAfter(now)) {
          final id1 = generateExamNotificationId(exam.id, 1);
          final timeStr = DateFormat('h:mm a').format(exam.examDate);

          await _plugin.zonedSchedule(
            id1,
            '📝 Exam Tomorrow: ${exam.title}',
            'Your ${exam.examType} is scheduled tomorrow at $timeStr. Stay confident!',
            tz.TZDateTime.from(oneDayBefore, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'trackx_exams',
                'Exam Reminders',
                channelDescription: 'Alerts and preparation reminders for upcoming exams',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'exam_reminder',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: '/exam-prep',
          );
        }

        // 2. Morning of the exam at 7:30 AM
        final morningOfExam = DateTime(
          exam.examDate.year,
          exam.examDate.month,
          exam.examDate.day,
          7,
          30,
        );

        if (morningOfExam.isAfter(now)) {
          final id2 = generateExamNotificationId(exam.id, 2);

          await _plugin.zonedSchedule(
            id2,
            '🔥 Exam Today: ${exam.title}',
            'Good luck with your ${exam.examType} examination today!',
            tz.TZDateTime.from(morningOfExam, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'trackx_exams',
                'Exam Reminders',
                channelDescription: 'Alerts and preparation reminders for upcoming exams',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'exam_reminder',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: '/exam-prep',
          );
        }

        // 3. 1 hour before exam start time
        final oneHourBefore = exam.examDate.subtract(const Duration(hours: 1));
        if (oneHourBefore.isAfter(now)) {
          final id3 = generateExamNotificationId(exam.id, 3);
          final timeStr = DateFormat('h:mm a').format(exam.examDate);

          await _plugin.zonedSchedule(
            id3,
            '⏰ Exam in 1 Hour: ${exam.title}',
            'Starting at $timeStr. Double check your admit card and essentials!',
            tz.TZDateTime.from(oneHourBefore, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'trackx_exams',
                'Exam Reminders',
                channelDescription: 'Alerts and preparation reminders for upcoming exams',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'exam_reminder',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: '/exam-prep',
          );
        }
      }
    } catch (_) {
      // Gracefully handle unsupported testing environments
    }
  }

  /// Cancel reminders for a specific exam
  Future<void> cancelExamReminders(String examId) async {
    try {
      await _plugin.cancel(generateExamNotificationId(examId, 1));
      await _plugin.cancel(generateExamNotificationId(examId, 2));
      await _plugin.cancel(generateExamNotificationId(examId, 3));
    } catch (_) {}
  }
}

final examNotificationServiceProvider =
    Provider<ExamNotificationService>((ref) {
  return ExamNotificationService();
});
