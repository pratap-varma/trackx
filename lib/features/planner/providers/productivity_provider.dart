import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/core/services/activity_logger.dart';
import 'package:trackx/features/notifications/services/exam_notification_service.dart';
import 'package:trackx/features/planner/data/repositories/productivity_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';

bool _isPastDay(DateTime date) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final itemDayStart = DateTime(date.year, date.month, date.day);
  return itemDayStart.isBefore(todayStart);
}

// --- Tasks State Notifier ---
class TasksNotifier extends StateNotifier<List<Task>> {
  final ProductivityRepository _repo;
  final Ref? _ref;
  TasksNotifier(this._repo, [this._ref]) : super([]) {
    state = _repo.getTasks();
    cleanupExpired();
  }

  void cleanupExpired() {
    final active = state.where((t) => !_isPastDay(t.dueDate)).toList();
    if (active.length != state.length) {
      state = active;
      _repo.saveTasks(state);
    }
  }

  void addTask(Task item) {
    state = [...state, item];
    _repo.saveTasks(state);
    _ref?.read(activityLoggerProvider).logEvent('task_created', parameters: {
      'taskId': item.id,
      'title': item.title,
      'category': item.category,
      'priority': item.priority,
    });
  }

  void editTask(Task item) {
    state = state.map((e) => e.id == item.id ? item : e).toList();
    _repo.saveTasks(state);
  }

  void deleteTask(String id) {
    state = state.where((e) => e.id != id).toList();
    _repo.saveTasks(state);
  }

  void toggleTask(String id) {
    state = state.map((e) {
      if (e.id == id) {
        final nextVal = !e.isCompleted;
        _ref?.read(activityLoggerProvider).logEvent(
          nextVal ? 'task_completed' : 'task_reopened',
          parameters: {
            'taskId': id,
            'title': e.title,
            'category': e.category,
          },
        );
        return e.copyWith(
          isCompleted: nextVal,
          completedAt: nextVal ? DateTime.now().millisecondsSinceEpoch : null,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return e;
    }).toList();
    _repo.saveTasks(state);
  }

  void restore(List<Task> list) {
    state = list.where((t) => !_isPastDay(t.dueDate)).toList();
    _repo.saveTasks(state);
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final repo = ref.watch(productivityRepositoryProvider);
  return TasksNotifier(repo, ref);
});

// --- Assignments State Notifier ---
class AssignmentsNotifier extends StateNotifier<List<Assignment>> {
  final ProductivityRepository _repo;
  final Ref? _ref;
  AssignmentsNotifier(this._repo, [this._ref]) : super([]) {
    state = _repo.getAssignments();
    cleanupExpired();
  }

  void cleanupExpired() {
    final active = state.where((a) => !_isPastDay(a.dueDate)).toList();
    if (active.length != state.length) {
      state = active;
      _repo.saveAssignments(state);
    }
  }

  void addAssignment(Assignment item) {
    state = [...state, item];
    _repo.saveAssignments(state);
    _ref?.read(activityLoggerProvider).logEvent('assignment_created', parameters: {
      'assignmentId': item.id,
      'title': item.title,
      'subjectId': item.subjectId,
    });
  }

  void editAssignment(Assignment item) {
    state = state.map((e) => e.id == item.id ? item : e).toList();
    _repo.saveAssignments(state);
  }

  void deleteAssignment(String id) {
    state = state.where((e) => e.id != id).toList();
    _repo.saveAssignments(state);
  }

  void toggleAssignment(String id) {
    state = state.map((e) {
      if (e.id == id) {
        final nextStatus = e.status == 'Completed'
            ? 'In progress'
            : 'Completed';
        _ref?.read(activityLoggerProvider).logEvent(
          nextStatus == 'Completed' ? 'assignment_completed' : 'assignment_reopened',
          parameters: {'assignmentId': id, 'title': e.title},
        );
        return e.copyWith(
          status: nextStatus,
          completedAt: nextStatus == 'Completed'
              ? DateTime.now().millisecondsSinceEpoch
              : null,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return e;
    }).toList();
    _repo.saveAssignments(state);
  }

  void restore(List<Assignment> list) {
    state = list.where((a) => !_isPastDay(a.dueDate)).toList();
    _repo.saveAssignments(state);
  }
}

final assignmentsProvider =
    StateNotifierProvider<AssignmentsNotifier, List<Assignment>>((ref) {
      final repo = ref.watch(productivityRepositoryProvider);
      return AssignmentsNotifier(repo, ref);
    });

// --- Exams State Notifier ---
class ExamsNotifier extends StateNotifier<List<Exam>> {
  final ProductivityRepository _repo;
  final ExamNotificationService? _notificationService;

  ExamsNotifier(this._repo, [this._notificationService]) : super([]) {
    state = _repo.getExams();
    cleanupExpired();
    _notificationService?.scheduleExamReminders(state);
  }

  void cleanupExpired() {
    final active = state.where((ex) => !_isPastDay(ex.examDate)).toList();
    if (active.length != state.length) {
      state = active;
      _repo.saveExams(state);
      _notificationService?.scheduleExamReminders(state);
    }
  }

  void addExam(Exam item) {
    state = [...state, item];
    _repo.saveExams(state);
    _notificationService?.scheduleExamReminders(state);
  }

  void editExam(Exam item) {
    state = state.map((e) => e.id == item.id ? item : e).toList();
    _repo.saveExams(state);
    _notificationService?.scheduleExamReminders(state);
  }

  void deleteExam(String id) {
    _notificationService?.cancelExamReminders(id);
    state = state.where((e) => e.id != id).toList();
    _repo.saveExams(state);
  }

  void updateProgress(String id, double value) {
    // Bounds check
    final clamped = value.clamp(0.0, 100.0);
    state = state
        .map((e) => e.id == id ? e.copyWith(preparationProgress: clamped) : e)
        .toList();
    _repo.saveExams(state);
  }

  void restore(List<Exam> list) {
    state = list.where((ex) => !_isPastDay(ex.examDate)).toList();
    _repo.saveExams(state);
    _notificationService?.scheduleExamReminders(state);
  }
}

final examsProvider = StateNotifierProvider<ExamsNotifier, List<Exam>>((ref) {
  final repo = ref.watch(productivityRepositoryProvider);
  final notificationService = ref.watch(examNotificationServiceProvider);
  return ExamsNotifier(repo, notificationService);
});

// --- Revision Topics State Notifier ---
class RevisionTopicsNotifier extends StateNotifier<List<RevisionTopic>> {
  final ProductivityRepository _repo;
  RevisionTopicsNotifier(this._repo) : super([]) {
    state = _repo.getRevisionTopics();
  }

  void addTopic(RevisionTopic item) {
    state = [...state, item];
    _repo.saveRevisionTopics(state);
  }

  void toggleTopic(String id) {
    state = state
        .map(
          (e) => e.id == id
              ? e.copyWith(
                  isCompleted: !e.isCompleted,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                )
              : e,
        )
        .toList();
    _repo.saveRevisionTopics(state);
  }

  void deleteTopic(String id) {
    state = state.where((e) => e.id != id).toList();
    _repo.saveRevisionTopics(state);
  }
}

final revisionTopicsProvider =
    StateNotifierProvider<RevisionTopicsNotifier, List<RevisionTopic>>((ref) {
      final repo = ref.watch(productivityRepositoryProvider);
      return RevisionTopicsNotifier(repo);
    });

// --- Notes State Notifier ---
class NotesNotifier extends StateNotifier<List<Note>> {
  final ProductivityRepository _repo;
  NotesNotifier(this._repo) : super([]) {
    state = _repo.getNotes();
  }

  void addNote(Note item) {
    state = [...state, item];
    _repo.saveNotes(state);
  }

  void editNote(Note item) {
    state = state.map((e) => e.id == item.id ? item : e).toList();
    _repo.saveNotes(state);
  }

  void deleteNote(String id) {
    state = state.where((e) => e.id != id).toList();
    _repo.saveNotes(state);
  }

  void toggleFavorite(String id) {
    state = state
        .map(
          (e) => e.id == id
              ? e.copyWith(
                  isFavorite: !e.isFavorite,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                )
              : e,
        )
        .toList();
    _repo.saveNotes(state);
  }

  void restore(List<Note> list) {
    state = list;
    _repo.saveNotes(state);
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  final repo = ref.watch(productivityRepositoryProvider);
  return NotesNotifier(repo);
});

// --- Study Sessions State Notifier ---
class StudySessionsNotifier extends StateNotifier<List<StudySession>> {
  final ProductivityRepository _repo;
  StudySessionsNotifier(this._repo) : super([]) {
    state = _repo.getStudySessions();
    cleanupExpired();
  }

  void cleanupExpired() {
    final active = state.where((s) => !_isPastDay(s.plannedDate)).toList();
    if (active.length != state.length) {
      state = active;
      _repo.saveStudySessions(state);
    }
  }

  void addSession(StudySession item) {
    state = [...state, item];
    _repo.saveStudySessions(state);
  }

  void toggleSession(String id) {
    state = state.map((e) {
      if (e.id == id) {
        final nextVal = e.status == 'Completed' ? 'Planned' : 'Completed';
        return e.copyWith(
          status: nextVal,
          completedAt: nextVal == 'Completed'
              ? DateTime.now().millisecondsSinceEpoch
              : null,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return e;
    }).toList();
    _repo.saveStudySessions(state);
  }

  void deleteSession(String id) {
    state = state.where((e) => e.id != id).toList();
    _repo.saveStudySessions(state);
  }
}

final studySessionsProvider =
    StateNotifierProvider<StudySessionsNotifier, List<StudySession>>((ref) {
      final repo = ref.watch(productivityRepositoryProvider);
      return StudySessionsNotifier(repo);
    });

// --- Grades State Notifier ---
class CourseGradesNotifier extends StateNotifier<List<CourseGrade>> {
  final ProductivityRepository _repo;
  CourseGradesNotifier(this._repo) : super([]) {
    state = _repo.getCourseGrades();
  }

  void addGrade(CourseGrade item) {
    state = [...state, item];
    _repo.saveCourseGrades(state);
  }

  void editGrade(CourseGrade item) {
    state = state.map((e) => e.id == item.id ? item : e).toList();
    _repo.saveCourseGrades(state);
  }

  void deleteGrade(String id) {
    state = state.where((e) => e.id != id).toList();
    _repo.saveCourseGrades(state);
  }
}

final courseGradesProvider =
    StateNotifierProvider<CourseGradesNotifier, List<CourseGrade>>((ref) {
      final repo = ref.watch(productivityRepositoryProvider);
      return CourseGradesNotifier(repo);
    });

// --- Holidays State Notifier ---
class HolidaysNotifier extends StateNotifier<List<AcademicHoliday>> {
  final ProductivityRepository _repo;
  HolidaysNotifier(this._repo) : super([]) {
    state = _repo.getHolidays();
  }

  void addHoliday(AcademicHoliday item) {
    state = [...state, item];
    _repo.saveHolidays(state);
  }

  void deleteHoliday(String id) {
    state = state.where((e) => e.id != id).toList();
    _repo.saveHolidays(state);
  }
}

final holidaysProvider =
    StateNotifierProvider<HolidaysNotifier, List<AcademicHoliday>>((ref) {
      final repo = ref.watch(productivityRepositoryProvider);
      return HolidaysNotifier(repo);
    });

// --- Smart Suggestions Provider ---
final smartSuggestionsProvider = Provider<List<String>>((ref) {
  final activeSem = ref.watch(activeSemesterProvider);
  if (activeSem == null) return [];

  final assignments = ref
      .watch(assignmentsProvider)
      .where((a) => a.semesterId == activeSem.id && a.status != 'Completed')
      .toList();
  final exams = ref
      .watch(examsProvider)
      .where(
        (e) => e.semesterId == activeSem.id && e.preparationProgress < 90.0,
      )
      .toList();
  final tasks = ref
      .watch(tasksProvider)
      .where((t) => t.semesterId == activeSem.id && !t.isCompleted)
      .toList();

  final List<String> suggestions = [];

  // Rules-based recommendation aggregation
  for (final ass in assignments) {
    final daysLeft = ass.dueDate.difference(DateTime.now()).inDays;
    if (daysLeft >= 0 && daysLeft <= 3) {
      suggestions.add(
        'Complete the assignment "${ass.title}" (Due in $daysLeft days).',
      );
    }
  }

  for (final ex in exams) {
    final daysLeft = ex.examDate.difference(DateTime.now()).inDays;
    if (daysLeft >= 0 && daysLeft <= 7) {
      suggestions.add(
        'Prepare for "${ex.title}" exam on ${ex.examDate.month}/${ex.examDate.day} (${ex.preparationProgress.toInt()}% completed).',
      );
    }
  }

  for (final t in tasks) {
    if (t.priority == 'Urgent') {
      suggestions.add('Urgent Task: Resolve "${t.title}" today.');
    }
  }

  if (suggestions.isEmpty) {
    suggestions.add('Looking good! Keep updating your attendance logs daily.');
  }

  return suggestions;
});

// --- CGPA / SGPA Calculations ---
final cgpaCalculatorProvider = Provider<Map<String, double>>((ref) {
  final grades = ref.watch(courseGradesProvider);
  if (grades.isEmpty) return {'cgpa': 0.0, 'sgpa': 0.0};

  double totalPoints = 0;
  int totalCredits = 0;

  for (final g in grades) {
    totalPoints += g.gradePoints * g.credits;
    totalCredits += g.credits;
  }

  final gpa = totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  return {
    'cgpa': gpa,
    'sgpa': gpa, // Defaults same for single semester simulation
  };
});
