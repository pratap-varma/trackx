import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
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
    required Map<String, bool> consentFlags,
    String? subjectFilterId,
  }) {
    // 1. Map subjects into AiSubjectContext selectively
    List<AiSubjectContext> subjectsContext = [];
    if (consentFlags['attendance'] ?? true) {
      subjectsContext = subjects.map((s) {
        final currentAtt = s.presentClasses + s.absentClasses == 0
            ? 0.0
            : (s.presentClasses / (s.presentClasses + s.absentClasses)) * 100;
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
        subjectsContext = subjectsContext.where((s) => s.id == subjectFilterId).toList();
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
        attendanceRecords = attendanceRecords.where((a) => a.subjectId == subjectFilterId).toList();
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
      preferences: {
        'targetAttendance': profile.globalTarget,
        'preferredLanguage': profile.preferredLanguage,
        'preferredTimezone': profile.preferredTimezone,
      },
      generatedAt: DateTime.now(),
    );
  }
}
