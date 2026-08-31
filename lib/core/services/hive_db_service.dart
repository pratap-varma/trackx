import 'package:hive_flutter/hive_flutter.dart';

class HiveDbService {
  static const String boxSemesters = 'px_hive_semesters';
  static const String boxSubjects = 'px_hive_subjects';
  static const String boxAttendance = 'px_hive_attendance';
  static const String boxTimetable = 'px_hive_timetable';
  static const String boxTasks = 'px_hive_tasks';
  static const String boxAssignments = 'px_hive_assignments';
  static const String boxExams = 'px_hive_exams';
  static const String boxNotes = 'px_hive_notes';
  static const String boxStudySessions = 'px_hive_study_sessions';
  static const String boxCgpa = 'px_hive_cgpa';
  static const String boxHolidays = 'px_hive_holidays';
  static const String boxSyncQueue = 'px_hive_sync_queue';
  static const String boxMetadata = 'px_hive_metadata';

  // Stage 16 boxes
  static const String boxProgrammes = 'px_hive_programmes';
  static const String boxDependencies = 'px_hive_dependencies';
  static const String boxScenarios = 'px_hive_scenarios';
  static const String boxCourses = 'px_hive_courses';
  static const String boxTopics = 'px_hive_topics';
  static const String boxResources = 'px_hive_resources';
  static const String boxFlashcards = 'px_hive_flashcards';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    // Open all required database boxes
    await Future.wait([
      Hive.openBox(boxSemesters),
      Hive.openBox(boxSubjects),
      Hive.openBox(boxAttendance),
      Hive.openBox(boxTimetable),
      Hive.openBox(boxTasks),
      Hive.openBox(boxAssignments),
      Hive.openBox(boxExams),
      Hive.openBox(boxNotes),
      Hive.openBox(boxStudySessions),
      Hive.openBox(boxCgpa),
      Hive.openBox(boxHolidays),
      Hive.openBox(boxSyncQueue),
      Hive.openBox(boxMetadata),
      Hive.openBox(boxProgrammes),
      Hive.openBox(boxDependencies),
      Hive.openBox(boxScenarios),
      Hive.openBox(boxCourses),
      Hive.openBox(boxTopics),
      Hive.openBox(boxResources),
      Hive.openBox(boxFlashcards),
    ]);

    _initialized = true;
  }

  bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  Box? getBoxOrNull(String boxName) {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return null;
  }

  Box getBox(String boxName) {
    return Hive.box(boxName);
  }

  Future<void> clearAll() async {
    await Future.wait([
      Hive.box(boxSemesters).clear(),
      Hive.box(boxSubjects).clear(),
      Hive.box(boxAttendance).clear(),
      Hive.box(boxTimetable).clear(),
      Hive.box(boxTasks).clear(),
      Hive.box(boxAssignments).clear(),
      Hive.box(boxExams).clear(),
      Hive.box(boxNotes).clear(),
      Hive.box(boxStudySessions).clear(),
      Hive.box(boxCgpa).clear(),
      Hive.box(boxHolidays).clear(),
      Hive.box(boxSyncQueue).clear(),
      Hive.box(boxMetadata).clear(),
      Hive.box(boxProgrammes).clear(),
      Hive.box(boxDependencies).clear(),
      Hive.box(boxScenarios).clear(),
      Hive.box(boxCourses).clear(),
      Hive.box(boxTopics).clear(),
      Hive.box(boxResources).clear(),
      Hive.box(boxFlashcards).clear(),
    ]);
  }
}
