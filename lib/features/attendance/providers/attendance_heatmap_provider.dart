import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/attendance/domain/models/attendance_heatmap_models.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';

final attendanceHeatmapProvider =
    Provider.family<HeatmapDataset, String?>((ref, subjectId) {
  final allRecords = ref.watch(attendanceRepositoryProvider);
  final activeSemester = ref.watch(activeSemesterProvider);
  final subjects = ref.watch(subjectRepositoryProvider);

  // Subject matching: match by id, or case-insensitive name / code
  final targetSubject = subjectId != null
      ? subjects
          .where((s) =>
              s.id == subjectId ||
              (s.name.toLowerCase() == subjectId.toLowerCase()) ||
              (s.code != null &&
                  s.code!.isNotEmpty &&
                  s.code!.toLowerCase() == subjectId.toLowerCase()))
          .firstOrNull
      : null;

  final filteredRecords = targetSubject != null
      ? allRecords
          .where((r) =>
              r.subjectId == targetSubject.id || r.subjectId == subjectId)
          .toList()
      : (subjectId != null
          ? allRecords.where((r) => r.subjectId == subjectId).toList()
          : allRecords);

  // Group records by normalized date (YYYY-MM-DD)
  final Map<DateTime, List<AttendanceRecord>> recordsByDay = {};

  for (final record in filteredRecords) {
    final normalized =
        DateTime(record.date.year, record.date.month, record.date.day);
    recordsByDay.putIfAbsent(normalized, () => []).add(record);
  }

  // Determine date bounds - ensure all record dates are included in the date range!
  final now = DateTime.now();
  final todayNormalized = DateTime(now.year, now.month, now.day);

  DateTime minRecordDate = todayNormalized;
  DateTime maxRecordDate = todayNormalized;

  if (filteredRecords.isNotEmpty) {
    for (final r in filteredRecords) {
      final rDate = DateTime(r.date.year, r.date.month, r.date.day);
      if (rDate.isBefore(minRecordDate)) minRecordDate = rDate;
      if (rDate.isAfter(maxRecordDate)) maxRecordDate = rDate;
    }
  }

  DateTime startDate;
  DateTime endDate;

  if (activeSemester != null) {
    final semStart = DateTime(
      activeSemester.startDate.year,
      activeSemester.startDate.month,
      activeSemester.startDate.day,
    );
    startDate = semStart.isBefore(minRecordDate) ? semStart : minRecordDate;

    final semEndDate = activeSemester.endDate ??
        activeSemester.startDate.add(const Duration(days: 150));
    final semEnd = DateTime(
      semEndDate.year,
      semEndDate.month,
      semEndDate.day,
    );
    endDate = semEnd.isAfter(maxRecordDate) ? semEnd : maxRecordDate;

    final maxFutureDate = todayNormalized.add(const Duration(days: 30));
    if (endDate.isAfter(maxFutureDate) && maxRecordDate.isBefore(maxFutureDate)) {
      endDate = maxFutureDate;
    }
  } else {
    final defaultStart = todayNormalized.subtract(const Duration(days: 180));
    startDate = defaultStart.isBefore(minRecordDate) ? defaultStart : minRecordDate;
    final defaultEnd = todayNormalized.add(const Duration(days: 14));
    endDate = defaultEnd.isAfter(maxRecordDate) ? defaultEnd : maxRecordDate;
  }

  // Align startDate to Sunday or Monday of the starting week
  final startWeekOffset = (startDate.weekday % 7); // 0 for Sunday
  startDate = startDate.subtract(Duration(days: startWeekOffset));

  // Align endDate to Saturday of ending week
  final endWeekOffset = (6 - (endDate.weekday % 7));
  endDate = endDate.add(Duration(days: endWeekOffset));

  final Map<DateTime, DayAttendanceSummary> daySummaries = {};

  int totalAttended = 0;
  int totalMissed = 0;
  int daysLogged = 0;

  DateTime cursor = startDate;
  while (!cursor.isAfter(endDate)) {
    final dayRecords = recordsByDay[cursor] ?? [];
    final summary = DayAttendanceSummary.fromRecords(cursor, dayRecords);
    daySummaries[cursor] = summary;

    totalAttended += summary.presentClasses;
    totalMissed += summary.absentClasses;
    if (summary.totalClasses > 0) {
      daysLogged++;
    }

    cursor = cursor.add(const Duration(days: 1));
  }

  // Calculate Streaks
  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 0;

  DateTime checkDate = startDate;
  while (!checkDate.isAfter(todayNormalized)) {
    final summary = daySummaries[checkDate];
    if (summary != null && summary.totalClasses > 0) {
      if (summary.status == DayAttendanceStatus.fullPresent ||
          summary.status == DayAttendanceStatus.partial) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (summary.status == DayAttendanceStatus.fullAbsent) {
        tempStreak = 0;
      }
    }
    checkDate = checkDate.add(const Duration(days: 1));
  }

  // Current streak looking backward from today
  DateTime backCheck = todayNormalized;
  while (!backCheck.isBefore(startDate)) {
    final summary = daySummaries[backCheck];
    if (summary != null && summary.totalClasses > 0) {
      if (summary.status == DayAttendanceStatus.fullPresent ||
          summary.status == DayAttendanceStatus.partial) {
        currentStreak++;
      } else if (summary.status == DayAttendanceStatus.fullAbsent) {
        break;
      }
    } else if (backCheck.isBefore(todayNormalized.subtract(const Duration(days: 7)))) {
      // Allow up to a week gap for weekends/holidays before resetting current streak
      break;
    }
    backCheck = backCheck.subtract(const Duration(days: 1));
  }

  return HeatmapDataset(
    daySummaries: daySummaries,
    startDate: startDate,
    endDate: endDate,
    totalClassesAttended: totalAttended,
    totalClassesMissed: totalMissed,
    totalDaysLogged: daysLogged,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
  );
});
