import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

class AiSubjectContext {
  final String id;
  final String name;
  final String? code;
  final double targetAttendance;
  final double currentAttendance;
  final double credits;

  AiSubjectContext({
    required this.id,
    required this.name,
    this.code,
    required this.targetAttendance,
    required this.currentAttendance,
    required this.credits,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'targetAttendance': targetAttendance,
      'currentAttendance': currentAttendance,
      'credits': credits,
    };
  }
}

class AiContext {
  final String? activeProgrammeId;
  final String? activeSemesterId;
  final List<AiSubjectContext> subjects;
  final List<Exam> upcomingExams;
  final List<Assignment> upcomingAssignments;
  final List<Task> plannerItems;
  final List<AttendanceRecord> attendance;
  final List<TimetableEntry> timetable;
  final Map<String, dynamic> preferences;
  final DateTime generatedAt;

  AiContext({
    this.activeProgrammeId,
    this.activeSemesterId,
    required this.subjects,
    required this.upcomingExams,
    required this.upcomingAssignments,
    required this.plannerItems,
    required this.attendance,
    required this.timetable,
    required this.preferences,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'activeProgrammeId': activeProgrammeId,
      'activeSemesterId': activeSemesterId,
      'subjects': subjects.map((e) => e.toMap()).toList(),
      'upcomingExams': upcomingExams.map((e) => e.toMap()).toList(),
      'upcomingAssignments': upcomingAssignments.map((e) => e.toMap()).toList(),
      'plannerItems': plannerItems.map((e) => e.toMap()).toList(),
      'attendance': attendance.map((e) => e.toMap()).toList(),
      'timetable': timetable.map((e) => e.toMap()).toList(),
      'preferences': preferences,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
