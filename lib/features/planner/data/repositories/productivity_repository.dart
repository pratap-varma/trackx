import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';

class ProductivityRepository {
  final SharedPreferences _prefs;

  ProductivityRepository(this._prefs);

  static const String _keyTasks = 'px_tasks_list';
  static const String _keyAssignments = 'px_assignments_list';
  static const String _keyExams = 'px_exams_list';
  static const String _keyRevisionTopics = 'px_revision_topics_list';
  static const String _keyNotes = 'px_notes_list';
  static const String _keyStudySessions = 'px_study_sessions_list';
  static const String _keyGrades = 'px_course_grades_list';
  static const String _keyHolidays = 'px_academic_holidays_list';

  // --- Tasks ---
  List<Task> getTasks() {
    final raw = _prefs.getString(_keyTasks);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Task.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<Task> list) async {
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyTasks, str);
  }

  // --- Assignments ---
  List<Assignment> getAssignments() {
    final raw = _prefs.getString(_keyAssignments);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Assignment.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAssignments(List<Assignment> list) async {
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyAssignments, str);
  }

  // --- Exams ---
  List<Exam> getExams() {
    final raw = _prefs.getString(_keyExams);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Exam.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExams(List<Exam> list) async {
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyExams, str);
  }

  // --- Revision Topics ---
  List<RevisionTopic> getRevisionTopics() {
    final raw = _prefs.getString(_keyRevisionTopics);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => RevisionTopic.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRevisionTopics(List<RevisionTopic> list) async {
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyRevisionTopics, str);
  }

  // --- Notes ---
  List<Note> getNotes() {
    final raw = _prefs.getString(_keyNotes);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Note.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotes(List<Note> list) async {
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyNotes, str);
  }

  // --- Study Sessions ---
  List<StudySession> getStudySessions() {
    final raw = _prefs.getString(_keyStudySessions);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => StudySession.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStudySessions(List<StudySession> list) async {
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyStudySessions, str);
  }

  // --- Grades ---
  List<CourseGrade> getCourseGrades() {
    final raw = _prefs.getString(_keyGrades);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => CourseGrade.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCourseGrades(List<CourseGrade> list) async {
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyGrades, str);
  }

  // --- Holidays ---
  List<AcademicHoliday> getHolidays() {
    final raw = _prefs.getString(_keyHolidays);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => AcademicHoliday.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHolidays(List<AcademicHoliday> list) async {
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyHolidays, str);
  }
}

final productivityRepositoryProvider = Provider<ProductivityRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProductivityRepository(prefs);
});
