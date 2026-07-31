import 'package:trackx/core/models/user_profile.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';

class AcademicContextBuilder {
  static Map<String, dynamic> buildContext({
    required UserProfile profile,
    required List<Semester> semesters,
    required List<Subject> subjects,
    required List<AttendanceRecord> attendance,
    required List<Task> tasks,
    required List<Assignment> assignments,
    required List<Exam> exams,
    required Map<String, bool> privacyConsent,
  }) {
    final Map<String, dynamic> context = {
      'profile': {
        'name': profile.name,
        'semester': profile.semester,
        'branch': profile.branch,
        'globalTarget': profile.globalTarget,
      },
    };

    // Include Attendance only if consent is given
    if (privacyConsent['attendance'] ?? true) {
      context['semesters'] = semesters
          .map((e) => {'id': e.id, 'name': e.name})
          .toList();

      context['subjects'] = subjects
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'targetOverride': e.targetOverride,
            },
          )
          .toList();

      context['attendanceCount'] = attendance.length;
    }

    // Include Tasks & Assignments only if consent is given
    if (privacyConsent['tasks'] ?? true) {
      context['tasks'] = tasks
          .where((t) => !t.isCompleted)
          .map(
            (t) => {
              'title': t.title,
              'priority': t.priority,
              'dueDate': t.dueDate?.toIso8601String(),
            },
          )
          .toList();
    }

    if (privacyConsent['assignments'] ?? true) {
      context['assignments'] = assignments
          .where((a) => a.status != 'Completed')
          .map(
            (a) => {'title': a.title, 'dueDate': a.dueDate.toIso8601String()},
          )
          .toList();
    }

    // Include Exams only if consent is given
    if (privacyConsent['exams'] ?? true) {
      context['exams'] = exams
          .map(
            (ex) => {
              'title': ex.title,
              'date': ex.examDate.toIso8601String(),
              'preparationProgress': ex.preparationProgress,
            },
          )
          .toList();
    }

    // Explicitly exclude private Notes and attachment contents by default
    context['notesExcluded'] = true;

    return context;
  }
}
