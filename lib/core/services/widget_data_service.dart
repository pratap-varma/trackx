import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/timetable/providers/timetable_provider.dart';
import 'package:trackx/theme/app_theme.dart';

class WidgetDataService {
  final SharedPreferences _prefs;
  static const MethodChannel _channel = MethodChannel('com.example.trackx/widget');
  static const String _widgetDataKey = 'px_home_widgets_data_v2';
  static const String refreshIntervalKey = 'widget_refresh_interval_minutes';
  Timer? _periodicTimer;

  WidgetDataService(this._prefs);

  int getRefreshIntervalMinutes() {
    return _prefs.getInt(refreshIntervalKey) ?? 30;
  }

  Future<void> setRefreshIntervalMinutes(int minutes) async {
    await _prefs.setInt(refreshIntervalKey, minutes);
    try {
      await _channel.invokeMethod('setRefreshInterval', {'intervalMinutes': minutes});
    } catch (_) {}
  }

  void startPeriodicSync(dynamic ref) {
    _periodicTimer?.cancel();
    final interval = getRefreshIntervalMinutes();
    _periodicTimer = Timer.periodic(Duration(minutes: interval > 0 ? interval : 30), (_) {
      syncWithAppData(ref);
    });
  }

  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> updateWidgetsData({
    // 1. Attendance Data
    required String overallAttendance,
    required String attendanceBadge,
    required String attendanceBunkInfo,
    required String attendanceTargetInfo,
    required String attendanceRatio,

    // 2. Schedule Data
    required String scheduleDay,
    required String scheduleBadge,
    required String nextClassMeta,
    required String nextClassName,
    required String nextClassRoom,
    required String scheduleSummary,
    required int classesToday,
    required String scheduleSlotsJson,

    // 3. Exams & Events Data
    required String examsHeader,
    required String examsBadge,
    required String nextExamMeta,
    required String nextExamTitle,
    required String nextExamDateTime,
    required String examsSummary,
    required int upcomingExamsCount,
    required String examsSlotsJson,

    // 4. Theme & Appearance Data
    String? themeMode,
    bool? isDark,
    String? accentColor,
  }) async {
    final Map<String, dynamic> data = {
      // 1. Attendance
      'overallAttendance': overallAttendance,
      'attendanceBadge': attendanceBadge,
      'attendanceBunkInfo': attendanceBunkInfo,
      'attendanceTargetInfo': attendanceTargetInfo,
      'attendanceRatio': attendanceRatio,

      // 2. Schedule
      'scheduleDay': scheduleDay,
      'scheduleBadge': scheduleBadge,
      'nextClassMeta': nextClassMeta,
      'nextClassName': nextClassName,
      'nextClassRoom': nextClassRoom,
      'scheduleSummary': scheduleSummary,
      'classesToday': classesToday,
      'scheduleSlotsJson': scheduleSlotsJson,

      // 3. Exams & Events
      'examsHeader': examsHeader,
      'examsBadge': examsBadge,
      'nextExamMeta': nextExamMeta,
      'nextExamTitle': nextExamTitle,
      'nextExamDateTime': nextExamDateTime,
      'examsSummary': examsSummary,
      'upcomingExamsCount': upcomingExamsCount,
      'examsSlotsJson': examsSlotsJson,

      // 4. Theme & Appearance
      'themeMode': themeMode ?? 'dark',
      'isDark': isDark ?? true,
      'accentColor': accentColor ?? '#5B5FEF',

      'refreshIntervalMinutes': getRefreshIntervalMinutes(),
      'lastUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _prefs.setString(_widgetDataKey, jsonEncode(data));

    // Broadcast update to Android native AppWidgets
    try {
      await _channel.invokeMethod('updateWidgets', data);
    } catch (_) {
      // Non-Android platforms or tests
    }
  }

  Future<void> syncWithAppData(dynamic ref) async {
    try {
      List<Subject> subjects = [];
      try {
        final raw = ref.read(subjectRepositoryProvider);
        if (raw is List<Subject>) {
          subjects = raw;
        } else if (raw is List) {
          subjects = raw.whereType<Subject>().toList();
        }
      } catch (_) {}

      List<TimetableEntry> timetableList = [];
      try {
        final raw = ref.read(timetableRepositoryProvider);
        if (raw is List<TimetableEntry>) {
          timetableList = raw;
        } else if (raw is List) {
          timetableList = raw.whereType<TimetableEntry>().toList();
        }
      } catch (_) {}

      List<Task> taskList = [];
      try {
        final raw = ref.read(tasksProvider);
        if (raw is List<Task>) {
          taskList = raw;
        } else if (raw is List) {
          taskList = raw.whereType<Task>().toList();
        }
      } catch (_) {}

      List<Exam> examList = [];
      try {
        final raw = ref.read(examsProvider);
        if (raw is List<Exam>) {
          examList = raw;
        } else if (raw is List) {
          examList = raw.whereType<Exam>().toList();
        }
      } catch (_) {}

      final now = DateTime.now();

      // ==========================================
      // 1. ATTENDANCE WIDGET DATA (Accurate Active Semester Stats)
      // ==========================================
      SemesterStats? stats;
      try {
        stats = ref.read(statsProvider) as SemesterStats?;
      } catch (_) {}

      final double overallAtt = stats?.overallPercentage ?? 0.0;
      final int totalAttended = stats?.totalPresent ?? 0;
      final int totalConducted = stats?.totalRecorded ?? 0;
      final double targetAtt = stats?.globalTarget ?? 75.0;
      final int overallSafeBunks = stats?.overallSafeBunks ?? 0;
      final int overallRequiredRecovery = stats?.overallRequiredRecovery ?? 0;

      final String overallAttString = totalConducted > 0 ? '${overallAtt.toStringAsFixed(1)}%' : '--%';
      String attendanceBadge = 'ON TRACK';
      String attendanceBunkInfo = 'Safe to Miss: -- classes';

      if (totalConducted > 0) {
        if (overallAtt >= targetAtt) {
          final bunks = overallSafeBunks;
          attendanceBadge = bunks > 0 ? 'SAFE' : 'ON TRACK';
          attendanceBunkInfo = bunks > 0
              ? 'Safe to Miss: $bunks ${bunks == 1 ? 'class' : 'classes'}'
              : 'Target achieved (${targetAtt.toInt()}%)';
        } else {
          final need = overallRequiredRecovery;
          attendanceBadge = 'LOW ATTENDANCE';
          attendanceBunkInfo = 'Attend next $need ${need == 1 ? 'class' : 'classes'}';
        }
      } else {
        attendanceBadge = subjects.isEmpty ? 'NO SUBJECTS' : 'NO DATA';
        attendanceBunkInfo = 'Add attendance records';
      }

      final String attendanceTargetInfo = 'Target: ${targetAtt.toInt()}%';
      final String attendanceRatio = totalConducted > 0
          ? '$totalAttended / $totalConducted Conducted'
          : '${subjects.length} Subjects enrolled';

      // ==========================================
      // 2. DAILY SCHEDULE WIDGET DATA (ALL PERIODS)
      // ==========================================
      final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
      final dayNameFormatted = DateFormat('EEEE, MMM d').format(now).toUpperCase();

      List<TimetableEntry> todaySlots = [];
      try {
        todaySlots = (ref.read(todayTimetableProvider) as List<TimetableEntry>).toList();
      } catch (_) {
        todaySlots = timetableList.where((slot) => slot.dayOfWeek == currentWeekday && slot.isEnabled).toList();
        todaySlots.sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      final int classesToday = todaySlots.length;
      final String scheduleDay = dayNameFormatted;
      final String scheduleBadge = classesToday > 0 ? '$classesToday ${classesToday == 1 ? 'CLASS' : 'CLASSES'}' : 'OFF DAY';

      final currentMinutes = now.hour * 60 + now.minute;
      final List<Map<String, String>> scheduleSlotsList = [];

      for (int i = 0; i < todaySlots.length; i++) {
        final slot = todaySlots[i];
        final subject = subjects.where((s) => s.id == slot.subjectId).firstOrNull;
        final periodBadge = slot.periodNumber > 0 ? 'P${slot.periodNumber}' : 'L${i + 1}';
        final isSubstituted = slot.isSubstituted;
        final baseName = subject?.name ?? (subjects.isNotEmpty ? subjects.first.name : 'Lecture');
        final subName = isSubstituted ? '$baseName (Proxy)' : baseName;
        final roomPart = (slot.room != null && slot.room!.isNotEmpty) ? ' • Room ${slot.room}' : '';
        final timeStr = '${slot.startTimeDisplay} - ${slot.endTimeDisplay}$roomPart';

        String status = '';
        if (currentMinutes >= slot.startTime && currentMinutes <= slot.endTime) {
          status = 'NOW';
        } else if (slot.startTime > currentMinutes) {
          status = 'UPCOMING';
        } else {
          status = 'DONE';
        }

        scheduleSlotsList.add({
          'badge': periodBadge,
          'name': subName,
          'time': timeStr,
          'status': status,
          'startMinutes': '${slot.startTime}',
          'endMinutes': '${slot.endTime}',
        });
      }

      final String scheduleSlotsJson = jsonEncode(scheduleSlotsList);
      final String scheduleSummary = classesToday > 0
          ? '$classesToday lectures scheduled today • Tap for timetable'
          : 'No classes today • Tap to customize timetable';

      String nextClassMeta = classesToday > 0 ? 'TODAY\'S LECTURES' : 'FREE DAY';
      String nextClassName = classesToday > 0 ? '$classesToday Classes Scheduled' : 'No classes today';
      String nextClassRoom = classesToday > 0 ? 'Check timetable for details' : 'Enjoy your day off';

      if (todaySlots.isNotEmpty) {
        final upcomingOrCurrent = todaySlots.firstWhere(
          (s) => s.endTime >= currentMinutes,
          orElse: () => todaySlots.first,
        );
        final sub = subjects.where((s) => s.id == upcomingOrCurrent.subjectId).firstOrNull;
        final name = sub?.name ?? (upcomingOrCurrent.isSubstituted ? 'Proxy Class' : 'Lecture');
        final room = (upcomingOrCurrent.room != null && upcomingOrCurrent.room!.isNotEmpty) ? 'Room ${upcomingOrCurrent.room}' : '';
        final timeStr = '${upcomingOrCurrent.startTimeDisplay} - ${upcomingOrCurrent.endTimeDisplay}';

        if (currentMinutes >= upcomingOrCurrent.startTime && currentMinutes <= upcomingOrCurrent.endTime) {
          nextClassMeta = 'HAPPENING NOW';
          nextClassName = name;
          nextClassRoom = '$timeStr${room.isNotEmpty ? ' • $room' : ''}';
        } else if (upcomingOrCurrent.startTime > currentMinutes) {
          nextClassMeta = 'NEXT CLASS';
          nextClassName = name;
          nextClassRoom = '$timeStr${room.isNotEmpty ? ' • $room' : ''}';
        } else {
          nextClassMeta = 'ALL CLASSES DONE';
          nextClassName = 'Done for today';
          nextClassRoom = '$classesToday classes completed';
        }
      }

      // ==========================================
      // 3. EXAMS & EVENTS WIDGET DATA (ALL FOR WEEK / MONTH)
      // ==========================================
      final todayDateOnly = DateTime(now.year, now.month, now.day);
      final List<Map<String, dynamic>> combinedEvents = [];

      // Add all upcoming exams
      for (final exam in examList) {
        final examDateOnly = DateTime(exam.examDate.year, exam.examDate.month, exam.examDate.day);
        if (!examDateOnly.isBefore(todayDateOnly)) {
          final diffDays = examDateOnly.difference(todayDateOnly).inDays;
          String badge;
          if (diffDays == 0) {
            badge = 'TODAY';
          } else if (diffDays == 1) {
            badge = 'TOMORROW';
          } else if (diffDays < 7) {
            badge = 'IN $diffDays DAYS';
          } else {
            badge = DateFormat('MMM d').format(exam.examDate).toUpperCase();
          }

          final typeStr = exam.examType.isNotEmpty ? exam.examType.toUpperCase() : 'EXAM';
          final timeStr = exam.startTime.isNotEmpty ? ' • ${exam.startTime}' : '';
          final detailsStr = exam.syllabus.isNotEmpty
              ? ' • ${exam.syllabus}'
              : (exam.notes?.isNotEmpty == true ? ' • ${exam.notes}' : '');
          final dateStr = DateFormat('EEE, MMM d').format(exam.examDate);

          combinedEvents.add({
            'date': examDateOnly,
            'badge': badge,
            'type': typeStr,
            'title': exam.title.isNotEmpty ? exam.title : 'Examination',
            'subtitle': '$dateStr$timeStr$detailsStr',
          });
        }
      }

      // Add all pending tasks
      for (final task in taskList) {
        if (!task.isCompleted) {
          final taskDateOnly = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          final diffDays = taskDateOnly.difference(todayDateOnly).inDays;
          String badge;
          if (diffDays < 0) {
            badge = 'OVERDUE';
          } else if (diffDays == 0) {
            badge = 'DUE TODAY';
          } else if (diffDays == 1) {
            badge = 'TOMORROW';
          } else if (diffDays < 7) {
            badge = 'IN $diffDays DAYS';
          } else {
            badge = DateFormat('MMM d').format(task.dueDate).toUpperCase();
          }

          final prioStr = task.priority.isNotEmpty ? task.priority.toUpperCase() : 'TASK';
          final dateStr = DateFormat('EEE, MMM d').format(task.dueDate);

          combinedEvents.add({
            'date': taskDateOnly,
            'badge': badge,
            'type': 'TASK',
            'title': task.title,
            'subtitle': 'Due $dateStr • $prioStr Priority',
          });
        }
      }

      // Sort all combined events chronologically by date
      combinedEvents.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      final List<Map<String, String>> examsSlotsList = combinedEvents.map((e) {
        return {
          'badge': e['badge'] as String,
          'type': e['type'] as String,
          'title': e['title'] as String,
          'subtitle': e['subtitle'] as String,
        };
      }).toList();

      final String examsSlotsJson = jsonEncode(examsSlotsList);
      final int totalEventsCount = combinedEvents.length;

      String examsHeader = 'EXAMS & EVENTS';
      String examsBadge = totalEventsCount > 0 ? '$totalEventsCount UPCOMING' : 'ALL CLEAR';
      String examsSummary = totalEventsCount > 0
          ? '$totalEventsCount upcoming ${totalEventsCount == 1 ? 'event/exam' : 'events & exams'} this month'
          : 'No upcoming exams or deadlines this month';

      String nextExamMeta = 'UPCOMING';
      String nextExamTitle = 'No upcoming exams scheduled';
      String nextExamDateTime = 'Add exams in Planner to track';

      if (combinedEvents.isNotEmpty) {
        final first = combinedEvents.first;
        nextExamMeta = '${first['badge']} • ${first['type']}';
        nextExamTitle = first['title'] as String;
        nextExamDateTime = first['subtitle'] as String;
      }

      // ==========================================
      // 4. THEME & APPEARANCE
      // ==========================================
      ThemeMode currentThemeMode = ThemeMode.dark;
      final savedThemeStr = _prefs.getString('app_theme_mode_setting');
      if (savedThemeStr == 'light') {
        currentThemeMode = ThemeMode.light;
      } else if (savedThemeStr == 'system') {
        currentThemeMode = ThemeMode.system;
      } else if (savedThemeStr == 'dark') {
        currentThemeMode = ThemeMode.dark;
      } else {
        try {
          currentThemeMode = ref.read(themeModeProvider) as ThemeMode;
        } catch (_) {}
      }

      Color currentAccent = const Color(0xFF5B5FEF);
      final savedAccentVal = _prefs.getInt('theme_accent_color_val');
      if (savedAccentVal != null) {
        currentAccent = Color(savedAccentVal);
      } else {
        try {
          currentAccent = ref.read(accentColorProvider) as Color;
        } catch (_) {}
      }

      final isPlatformDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      final bool isDark = currentThemeMode == ThemeMode.dark ||
          (currentThemeMode == ThemeMode.system && isPlatformDark);
      final String themeModeStr = currentThemeMode == ThemeMode.light
          ? 'light'
          : (currentThemeMode == ThemeMode.system ? 'system' : 'dark');
      final String accentHex =
          '#${(currentAccent.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

      await updateWidgetsData(
        overallAttendance: overallAttString,
        attendanceBadge: attendanceBadge,
        attendanceBunkInfo: attendanceBunkInfo,
        attendanceTargetInfo: attendanceTargetInfo,
        attendanceRatio: attendanceRatio,

        scheduleDay: scheduleDay,
        scheduleBadge: scheduleBadge,
        nextClassMeta: nextClassMeta,
        nextClassName: nextClassName,
        nextClassRoom: nextClassRoom,
        scheduleSummary: scheduleSummary,
        classesToday: classesToday,
        scheduleSlotsJson: scheduleSlotsJson,

        examsHeader: examsHeader,
        examsBadge: examsBadge,
        nextExamMeta: nextExamMeta,
        nextExamTitle: nextExamTitle,
        nextExamDateTime: nextExamDateTime,
        examsSummary: examsSummary,
        upcomingExamsCount: totalEventsCount,
        examsSlotsJson: examsSlotsJson,

        themeMode: themeModeStr,
        isDark: isDark,
        accentColor: accentHex,
      );
    } catch (_) {}
  }

  Map<String, dynamic> getWidgetData() {
    final raw = _prefs.getString(_widgetDataKey);
    if (raw == null) {
      return _defaultWidgetData();
    }
    try {
      return jsonDecode(raw);
    } catch (_) {
      return _defaultWidgetData();
    }
  }

  Map<String, dynamic> _defaultWidgetData() {
    return {
      'overallAttendance': '--%',
      'attendanceBadge': 'ON TRACK',
      'attendanceBunkInfo': 'Safe to Bunk: -- classes',
      'attendanceTargetInfo': 'Target: 75%',
      'attendanceRatio': '-- / -- Conducted',

      'scheduleDay': 'DAILY SCHEDULE',
      'scheduleBadge': 'TODAY',
      'nextClassMeta': 'TODAY\'S CLASSES',
      'nextClassName': 'No classes scheduled today',
      'nextClassRoom': '',
      'scheduleSummary': 'Tap to view full timetable',
      'classesToday': 0,
      'scheduleSlotsJson': '[]',

      'examsHeader': 'EXAMS & EVENTS',
      'examsBadge': 'SCHEDULED',
      'nextExamMeta': 'UPCOMING EXAM',
      'nextExamTitle': 'No upcoming exams scheduled',
      'nextExamDateTime': 'Add exams in Planner to track',
      'examsSummary': '0 upcoming exams • 0 tasks pending',
      'upcomingExamsCount': 0,
      'examsSlotsJson': '[]',
      'themeMode': 'dark',
      'isDark': true,
      'accentColor': '#5B5FEF',
      'lastUpdatedAt': 0,
    };
  }
}

final widgetDataServiceProvider = Provider<WidgetDataService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WidgetDataService(prefs);
});
