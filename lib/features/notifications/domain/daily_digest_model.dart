import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

class DailyDigestSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const DailyDigestSettings({
    this.enabled = true,
    this.hour = 7,
    this.minute = 0,
  });

  DailyDigestSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return DailyDigestSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
    };
  }

  factory DailyDigestSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DailyDigestSettings();
    return DailyDigestSettings(
      enabled: map['enabled'] as bool? ?? true,
      hour: map['hour'] as int? ?? 7,
      minute: map['minute'] as int? ?? 0,
    );
  }
}

class DailyDigestMessage {
  final String title;
  final String body;
  final bool isUrgent;

  const DailyDigestMessage({
    required this.title,
    required this.body,
    this.isUrgent = false,
  });
}

class DailyDigestComposer {
  static DailyDigestMessage compose({
    required List<TimetableEntry> todayClasses,
    required List<SubjectStats> allSubjectStats,
    required List<Task> todayTasks,
    required List<Exam> upcomingExams,
    required bool hasSubjectsConfigured,
  }) {
    // 1. Edge Case: New user / no timetable or subjects configured
    if (!hasSubjectsConfigured) {
      return const DailyDigestMessage(
        title: '☀️ Welcome to TrackX',
        body:
            'Set up your timetable & subjects in TrackX to receive your daily morning briefing.',
      );
    }

    // 2. Identify attendance risks (lead with most urgent info)
    SubjectStats? criticalSubject;
    SubjectStats? warningSubject;

    // Check subjects scheduled today first, then other subjects
    final todaySubjectIds = todayClasses.map((e) => e.subjectId).toSet();

    for (final stats in allSubjectStats) {
      if (stats.requiredRecovery > 0) {
        // Attendance is below target
        if (todaySubjectIds.contains(stats.subject.id)) {
          criticalSubject = stats;
          break; // Priority to subject happening today
        }
        criticalSubject ??= stats;
      } else if (stats.safeBunks == 0 && stats.totalCount > 0) {
        // At threshold (1 more miss drops below target)
        if (todaySubjectIds.contains(stats.subject.id)) {
          warningSubject = stats;
        }
        warningSubject ??= stats;
      }
    }

    final tasksDueToday = todayTasks.where((t) => !t.isCompleted).length;
    final examsToday = upcomingExams.where((e) {
      final now = DateTime.now();
      return e.examDate.year == now.year &&
          e.examDate.month == now.month &&
          e.examDate.day == now.day;
    }).length;

    // Case A: Critical Attendance Deficit
    if (criticalSubject != null) {
      final subName = criticalSubject.subject.name;
      final pct = criticalSubject.percentage.toInt();
      final target = criticalSubject.target.toInt();
      final req = criticalSubject.requiredRecovery;

      final buffer = StringBuffer();
      buffer.write(
          '⚠️ $subName is at $pct% (target $target%). Attend $req more to recover.');

      if (todayClasses.isNotEmpty) {
        buffer.write(' You have ${todayClasses.length} class${todayClasses.length > 1 ? "es" : ""} today.');
      }
      if (tasksDueToday > 0) {
        buffer.write(' ($tasksDueToday task${tasksDueToday > 1 ? "s" : ""} due).');
      }

      return DailyDigestMessage(
        title: '⚠️ Attendance Alert: $subName',
        body: buffer.toString(),
        isUrgent: true,
      );
    }

    // Case B: Threshold Warning (0 safe bunks)
    if (warningSubject != null) {
      final subName = warningSubject.subject.name;
      final pct = warningSubject.percentage.toInt();
      final target = warningSubject.target.toInt();

      final buffer = StringBuffer();
      buffer.write(
          '$subName is at $pct% — 1 more miss and you drop below $target%.');

      if (todayClasses.isNotEmpty) {
        buffer.write(' ${todayClasses.length} class${todayClasses.length > 1 ? "es" : ""} scheduled today.');
      }
      if (tasksDueToday > 0) {
        buffer.write(' $tasksDueToday task${tasksDueToday > 1 ? "s" : ""} due.');
      }

      return DailyDigestMessage(
        title: '⚡ Attendance Heads-Up: $subName',
        body: buffer.toString(),
        isUrgent: true,
      );
    }

    // Case C: Normal Day with Scheduled Classes (No Attendance Risk)
    if (todayClasses.isNotEmpty) {
      final firstClass = todayClasses.first;
      final buffer = StringBuffer();
      buffer.write(
          'You have ${todayClasses.length} class${todayClasses.length > 1 ? "es" : ""} today (first at ${firstClass.startTimeDisplay}). All attendance targets are healthy!');

      if (examsToday > 0) {
        buffer.write(' 📝 Exam scheduled today!');
      } else if (tasksDueToday > 0) {
        buffer.write(' $tasksDueToday task${tasksDueToday > 1 ? "s" : ""} due today.');
      }

      return DailyDigestMessage(
        title: '☀️ Daily Morning Digest',
        body: buffer.toString(),
      );
    }

    // Case D: No Classes Today (Weekend / Holiday)
    if (examsToday > 0 || tasksDueToday > 0) {
      final buffer = StringBuffer('No classes today, but you have ');
      if (examsToday > 0) {
        buffer.write('$examsToday exam${examsToday > 1 ? "s" : ""} ');
      }
      if (tasksDueToday > 0) {
        if (examsToday > 0) buffer.write('and ');
        buffer.write('$tasksDueToday task${tasksDueToday > 1 ? "s" : ""} due today. ');
      }
      buffer.write('Have a productive day!');

      return DailyDigestMessage(
        title: '☀️ TrackX Daily Briefing',
        body: buffer.toString(),
      );
    }

    // Case E: Calm Free Day
    return const DailyDigestMessage(
      title: '☀️ Free Day',
      body: 'No classes or pending tasks scheduled for today. Enjoy your day off!',
    );
  }
}
