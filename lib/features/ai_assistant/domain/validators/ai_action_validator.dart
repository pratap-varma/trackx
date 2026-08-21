import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';

class AiActionValidation {
  final bool isValid;
  final String? reason;

  AiActionValidation({required this.isValid, this.reason});
}

class AiActionValidator {
  static AiActionValidation validatePlannerTask(
    Task task, {
    List<Exam> exams = const [],
    List<Assignment> assignments = const [],
  }) {
    final now = DateTime.now();
    if (task.dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return AiActionValidation(
        isValid: false,
        reason: 'Task scheduled date is in the past.',
      );
    }

    // Check if task date is past related deadlines
    for (final exam in exams) {
      if (task.title.toLowerCase().contains(exam.title.toLowerCase())) {
        if (task.dueDate.isAfter(exam.examDate)) {
          return AiActionValidation(
            isValid: false,
            reason:
                'Task is scheduled after the related exam date (${exam.examDate.year}-${exam.examDate.month}-${exam.examDate.day}).',
          );
        }
      }
    }

    return AiActionValidation(isValid: true);
  }

  static AiActionValidation validateStudySession(
    String subjectId,
    DateTime date,
    int durationMinutes, {
    List<Subject> subjects = const [],
    List<Exam> exams = const [],
  }) {
    final now = DateTime.now();
    if (date.isBefore(now)) {
      return AiActionValidation(
        isValid: false,
        reason: 'Study session start time is in the past.',
      );
    }

    if (durationMinutes <= 0 || durationMinutes > 360) {
      return AiActionValidation(
        isValid: false,
        reason:
            'Study session duration must be positive and less than 6 hours.',
      );
    }

    // Check that target subject exists
    final hasSubject = subjects.any((s) => s.id == subjectId);
    if (!hasSubject && subjects.isNotEmpty) {
      return AiActionValidation(
        isValid: false,
        reason: 'Subject ID "$subjectId" not found in active semester.',
      );
    }

    // Check if session conflicts with an exam
    final sessionEnd = date.add(Duration(minutes: durationMinutes));
    for (final exam in exams) {
      final examEnd = exam.examDate.add(
        const Duration(hours: 3),
      ); // assume 3 hour exam
      if (date.isBefore(examEnd) && sessionEnd.isAfter(exam.examDate)) {
        return AiActionValidation(
          isValid: false,
          reason:
              'Study session overlaps with the scheduled exam "${exam.title}".',
        );
      }
    }

    return AiActionValidation(isValid: true);
  }
}
