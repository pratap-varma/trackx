import 'package:flutter/material.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';

enum DayAttendanceStatus {
  fullPresent,
  partial,
  fullAbsent,
  holidayOrCancelled,
  noClasses,
}

class DayAttendanceSummary {
  final DateTime date;
  final List<AttendanceRecord> records;
  final int totalClasses;
  final int presentClasses;
  final int absentClasses;
  final int cancelledClasses;

  DayAttendanceSummary({
    required this.date,
    required this.records,
    required this.totalClasses,
    required this.presentClasses,
    required this.absentClasses,
    required this.cancelledClasses,
  });

  factory DayAttendanceSummary.fromRecords(
    DateTime date,
    List<AttendanceRecord> dayRecords,
  ) {
    if (dayRecords.isEmpty) {
      return DayAttendanceSummary(
        date: date,
        records: [],
        totalClasses: 0,
        presentClasses: 0,
        absentClasses: 0,
        cancelledClasses: 0,
      );
    }

    int present = 0;
    int absent = 0;
    int cancelled = 0;

    for (final r in dayRecords) {
      final s = r.status.toLowerCase();
      if (s == 'present') {
        present++;
      } else if (s == 'absent') {
        absent++;
      } else if (s == 'cancelled' || s == 'holiday') {
        cancelled++;
      }
    }

    return DayAttendanceSummary(
      date: date,
      records: dayRecords,
      totalClasses: dayRecords.length,
      presentClasses: present,
      absentClasses: absent,
      cancelledClasses: cancelled,
    );
  }

  DayAttendanceStatus get status {
    if (totalClasses == 0) return DayAttendanceStatus.noClasses;
    if (cancelledClasses == totalClasses) {
      return DayAttendanceStatus.holidayOrCancelled;
    }
    final activeClasses = presentClasses + absentClasses;
    if (activeClasses == 0) return DayAttendanceStatus.holidayOrCancelled;
    if (presentClasses == activeClasses) return DayAttendanceStatus.fullPresent;
    if (absentClasses == activeClasses) return DayAttendanceStatus.fullAbsent;
    return DayAttendanceStatus.partial;
  }

  double get percentage {
    final activeClasses = presentClasses + absentClasses;
    if (activeClasses == 0) return 0.0;
    return (presentClasses / activeClasses) * 100.0;
  }

  Color get statusColor {
    switch (status) {
      case DayAttendanceStatus.fullPresent:
        return const Color(0xFF10B981); // Emerald Green
      case DayAttendanceStatus.partial:
        return const Color(0xFF3B82F6); // Electric Blue
      case DayAttendanceStatus.fullAbsent:
        return const Color(0xFFEF4444); // Crimson Red
      case DayAttendanceStatus.holidayOrCancelled:
        return const Color(0xFF8151EB); // Purple
      case DayAttendanceStatus.noClasses:
        return Colors.white.withValues(alpha: 0.04);
    }
  }
}

class HeatmapDataset {
  final Map<DateTime, DayAttendanceSummary> daySummaries;
  final DateTime startDate;
  final DateTime endDate;
  final int totalClassesAttended;
  final int totalClassesMissed;
  final int totalDaysLogged;
  final int currentStreak;
  final int longestStreak;

  HeatmapDataset({
    required this.daySummaries,
    required this.startDate,
    required this.endDate,
    required this.totalClassesAttended,
    required this.totalClassesMissed,
    required this.totalDaysLogged,
    required this.currentStreak,
    required this.longestStreak,
  });

  double get overallPercentage {
    final total = totalClassesAttended + totalClassesMissed;
    if (total == 0) return 0.0;
    return (totalClassesAttended / total) * 100.0;
  }
}
