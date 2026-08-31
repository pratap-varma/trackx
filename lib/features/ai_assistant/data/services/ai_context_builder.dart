import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_context.dart';

class AiContextBuilder {
  static AiContext build({
    required UserProfile profile,
    required List<Semester> semesters,
    required List<Subject> subjects,
    required List<AttendanceRecord> attendance,
    required List<Task> tasks,
    required List<Assignment> assignments,
    required List<Exam> exams,
    required List<TimetableEntry> timetable,
    required Map<String, bool> consentFlags,
    String? subjectFilterId,
  }) {
    // 1. Map subjects into AiSubjectContext selectively
    List<AiSubjectContext> subjectsContext = [];
    if (consentFlags['attendance'] ?? true) {
      subjectsContext = subjects.map((s) {
        final subRecords = attendance.where((a) => a.subjectId == s.id).toList();
        final present = subRecords.isNotEmpty
            ? subRecords.where((a) => a.status == 'present').length
            : s.presentClasses;
        final total = subRecords.isNotEmpty
            ? subRecords.length
            : (s.presentClasses + s.absentClasses);
        final currentAtt = total == 0 ? 0.0 : (present / total) * 100;
        return AiSubjectContext(
          id: s.id,
          name: s.name,
          code: s.code,
          targetAttendance: s.targetAttendance,
          currentAttendance: currentAtt,
          credits: s.credits ?? 0.0,
        );
      }).toList();

      if (subjectFilterId != null) {
        subjectsContext = subjectsContext
            .where((s) => s.id == subjectFilterId)
            .toList();
      }
    }

    // 2. Selectively filter exams
    List<Exam> examsContext = [];
    if (consentFlags['exams'] ?? true) {
      examsContext = exams;
    }

    // 3. Selectively filter assignments
    List<Assignment> assignmentsContext = [];
    if (consentFlags['assignments'] ?? true) {
      assignmentsContext = assignments;
    }

    // 4. Selectively filter tasks
    List<Task> tasksContext = [];
    if (consentFlags['tasks'] ?? true) {
      tasksContext = tasks;
    }

    // 5. Selectively filter attendance records
    List<AttendanceRecord> attendanceRecords = [];
    if (consentFlags['attendance'] ?? true) {
      attendanceRecords = attendance;
      if (subjectFilterId != null) {
        attendanceRecords = attendanceRecords
            .where((a) => a.subjectId == subjectFilterId)
            .toList();
      }
    }

    // 6. Selectively filter timetable entries
    List<TimetableEntry> timetableContext = [];
    if (consentFlags['attendance'] ?? true) {
      timetableContext = timetable;
      if (subjectFilterId != null) {
        timetableContext = timetableContext
            .where((t) => t.subjectId == subjectFilterId)
            .toList();
      }
    }

    return AiContext(
      activeProgrammeId: profile.programmeName,
      activeSemesterId: profile.currentSemesterId,
      subjects: subjectsContext,
      upcomingExams: examsContext,
      upcomingAssignments: assignmentsContext,
      plannerItems: tasksContext,
      attendance: attendanceRecords,
      timetable: timetableContext,
      preferences: {
        'targetAttendance': profile.globalTarget,
        'preferredLanguage': profile.preferredLanguage,
        'preferredTimezone': profile.preferredTimezone,
      },
      generatedAt: DateTime.now(),
    );
  }
}
