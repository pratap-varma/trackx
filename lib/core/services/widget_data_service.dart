import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

class WidgetDataService {
  final SharedPreferences _prefs;
  static const MethodChannel _channel = MethodChannel('com.example.trackx/widget');
  static const String _widgetDataKey = 'px_home_widget_summary_data';

  WidgetDataService(this._prefs);

  Future<void> updateWidgetData({
    required double overallAttendance,
    required int classesToday,
    required String nextClassName,
    String nextClassTime = '',
    String nextClassRoom = '',
    required String alertMessage,
    int tasksPending = 0,
  }) async {
    final Map<String, dynamic> data = {
      'overallAttendance': overallAttendance,
      'classesToday': classesToday,
      'nextClassName': nextClassName,
      'nextClassTime': nextClassTime,
      'nextClassRoom': nextClassRoom,
      'alertMessage': alertMessage,
      'tasksPending': tasksPending,
      'lastUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _prefs.setString(_widgetDataKey, jsonEncode(data));

    // Broadcast update to Android native AppWidget
    try {
      final attString = overallAttendance > 0 ? '${overallAttendance.toStringAsFixed(1)}%' : '';
      await _channel.invokeMethod('updateWidget', {
        'overallAttendance': attString,
        'classesToday': classesToday,
        'nextClassName': nextClassName,
        'nextClassTime': nextClassTime,
        'nextClassRoom': nextClassRoom,
        'alertMessage': alertMessage,
        'tasksPending': tasksPending,
      });
    } catch (_) {
      // Non-Android platforms or tests
    }
  }

  Future<void> syncWithAppData(dynamic ref) async {
    try {
      final subjects = ref.read(subjectRepositoryProvider) as List<Subject>;
      final timetableList = ref.read(timetableRepositoryProvider) as List<TimetableEntry>;
      final taskList = ref.read(tasksProvider) as List<Task>;

      double overallAtt = 0.0;
      if (subjects.isNotEmpty) {
        int totalAttended = 0;
        int totalConducted = 0;
        for (final Subject sub in subjects) {
          totalAttended += sub.presentClasses;
          totalConducted += (sub.presentClasses + sub.absentClasses);
        }
        if (totalConducted > 0) {
          overallAtt = (totalAttended / totalConducted) * 100.0;
        }
      }

      final now = DateTime.now();
      final currentWeekday = now.weekday; // 1 = Monday, 6 = Saturday
      final todaySlots = timetableList.where((slot) => slot.dayOfWeek == currentWeekday && slot.isEnabled).toList();
      todaySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

      int classesToday = todaySlots.length;
      String nextClassName = 'None';
      String nextClassTime = '';
      String nextClassRoom = '';

      final currentMinutes = now.hour * 60 + now.minute;
      for (final slot in todaySlots) {
        if (slot.startTime >= currentMinutes) {
          final subject = subjects.where((s) => s.id == slot.subjectId).firstOrNull;
          nextClassName = subject?.name ?? (subjects.isNotEmpty ? subjects.first.name : 'Class');
          nextClassTime = slot.startTimeDisplay;
          nextClassRoom = slot.room ?? '';
          break;
        }
      }

      if (nextClassName == 'None' && todaySlots.isNotEmpty) {
        final firstSlot = todaySlots.first;
        final subject = subjects.where((s) => s.id == firstSlot.subjectId).firstOrNull;
        nextClassName = subject?.name ?? (subjects.isNotEmpty ? subjects.first.name : 'Class');
        nextClassTime = firstSlot.startTimeDisplay;
        nextClassRoom = firstSlot.room ?? '';
      }

      final pendingTasks = taskList.where((t) => !t.isCompleted).length;
      final alertMsg = nextClassName != 'None' ? 'Next: $nextClassName at $nextClassTime' : 'No more classes today';

      await updateWidgetData(
        overallAttendance: overallAtt,
        classesToday: classesToday,
        nextClassName: nextClassName,
        nextClassTime: nextClassTime,
        nextClassRoom: nextClassRoom,
        alertMessage: alertMsg,
        tasksPending: pendingTasks,
      );
    } catch (_) {}
  }

  Map<String, dynamic> getWidgetData() {
    final raw = _prefs.getString(_widgetDataKey);
    if (raw == null) {
      return {
        'overallAttendance': 0.0,
        'classesToday': 0,
        'nextClassName': 'None',
        'nextClassTime': '',
        'nextClassRoom': '',
        'alertMessage': 'No Alerts',
        'tasksPending': 0,
        'lastUpdatedAt': 0,
      };
    }
    try {
      return jsonDecode(raw);
    } catch (_) {
      return {
        'overallAttendance': 0.0,
        'classesToday': 0,
        'nextClassName': 'None',
        'nextClassTime': '',
        'nextClassRoom': '',
        'alertMessage': 'No Alerts',
        'tasksPending': 0,
        'lastUpdatedAt': 0,
      };
    }
  }
}

final widgetDataServiceProvider = Provider<WidgetDataService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WidgetDataService(prefs);
});
