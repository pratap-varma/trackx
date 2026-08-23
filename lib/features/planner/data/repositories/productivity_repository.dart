import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';

class ProductivityRepository {
  final SharedPreferences _prefs;
  final Ref? _ref;

  ProductivityRepository(this._prefs, [this._ref]);

  static const String _keyTasks = 'px_tasks_list';
  static const String _keyAssignments = 'px_assignments_list';
  static const String _keyExams = 'px_exams_list';
  static const String _keyRevisionTopics = 'px_revision_topics_list';
  static const String _keyNotes = 'px_notes_list';
  static const String _keyStudySessions = 'px_study_sessions_list';
  static const String _keyGrades = 'px_course_grades_list';
  static const String _keyHolidays = 'px_academic_holidays_list';

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey(String baseKey, [String? uidOverride]) {
    final uid = uidOverride ?? _currentUserId;
    if (uid.isEmpty) return baseKey;
    return '${uid}_$baseKey';
  }

  bool _isPastDay(DateTime date) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final itemDayStart = DateTime(date.year, date.month, date.day);
    return itemDayStart.isBefore(todayStart);
  }

  // --- Tasks ---
  List<Task> getTasks([String? uidOverride]) {
    final uid = uidOverride ?? _currentUserId;
    if (uid.isEmpty) return [];
    final raw = _prefs.getString(_getKey(_keyTasks, uid));
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      final allTasks = decoded
          .map((e) => Task.fromMap(e))
          .where(
            (t) => t.userId == uid || t.userId.isEmpty || t.userId == 'user',
          )
          .toList();
      // Automatically clean up / delete tasks after the scheduled day has completed
      final activeTasks = allTasks.where((t) => !_isPastDay(t.dueDate)).toList();
      if (activeTasks.length != allTasks.length) {
        saveTasks(activeTasks, uid);
      }
      return activeTasks;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<Task> list, [String? uidOverride]) async {
    final uid = uidOverride ?? _currentUserId;
    if (uid.isEmpty) return;
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_getKey(_keyTasks, uid), str);
  }

  // --- Assignments ---
  List<Assignment> getAssignments([String? uidOverride]) {
    final uid = uidOverride ?? _currentUserId;
    if (uid.isEmpty) return [];
    final raw = _prefs.getString(_getKey(_keyAssignments, uid));
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      final allAssignments = decoded
          .map((e) => Assignment.fromMap(e))
          .where(
            (a) => a.userId == uid || a.userId.isEmpty || a.userId == 'user',
          )
          .toList();
      // Automatically delete assignments after the scheduled due date has passed
      final activeAssignments =
          allAssignments.where((a) => !_isPastDay(a.dueDate)).toList();
      if (activeAssignments.length != allAssignments.length) {
        saveAssignments(activeAssignments, uid);
      }
      return activeAssignments;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAssignments(
    List<Assignment> list, [
    String? uidOverride,
  ]) async {
    final uid = uidOverride ?? _currentUserId;
    if (uid.isEmpty) return;
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_getKey(_keyAssignments, uid), str);
  }

  // --- Exams ---
  List<Exam> getExams([String? uidOverride]) {
    final uid = uidOverride ?? _currentUserId;
    if (uid.isEmpty) return [];
    final raw = _prefs.getString(_getKey(_keyExams, uid));
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      final allExams = decoded
          .map((e) => Exam.fromMap(e))
          .where(
            (ex) =>
                ex.userId == uid || ex.userId.isEmpty || ex.userId == 'user',
          )
          .toList();
      // Automatically delete exams after the scheduled exam date has completed
      final activeExams =
          allExams.where((ex) => !_isPastDay(ex.examDate)).toList();
      if (activeExams.length != allExams.length) {
        saveExams(activeExams, uid);
      }
      return activeExams;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExams(List<Exam> list, [String? uidOverride]) async {
    final uid = uidOverride ?? _currentUserId;
    if (uid.isEmpty) return;
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_getKey(_keyExams, uid), str);
  }

  // --- Revision Topics ---
  List<RevisionTopic> getRevisionTopics() {
    final uid = _currentUserId;
    if (uid.isEmpty) return [];
    final raw = _prefs.getString(_getKey(_keyRevisionTopics));
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => RevisionTopic.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRevisionTopics(List<RevisionTopic> list) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return;
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_getKey(_keyRevisionTopics), str);
  }

  // --- Notes ---
  List<Note> getNotes() {
    final uid = _currentUserId;
    if (uid.isEmpty) return [];
    final raw = _prefs.getString(_getKey(_keyNotes));
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Note.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotes(List<Note> list) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return;
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_getKey(_keyNotes), str);
  }

  // --- Study Sessions ---
  List<StudySession> getStudySessions() {
    final uid = _currentUserId;
    if (uid.isEmpty) return [];
    final raw = _prefs.getString(_getKey(_keyStudySessions));
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      final allSessions = decoded
          .map((e) => StudySession.fromMap(e))
          .where(
            (s) => s.userId == uid || s.userId.isEmpty || s.userId == 'user',
          )
          .toList();
      // Automatically delete study sessions after the scheduled date has passed
      final activeSessions =
          allSessions.where((s) => !_isPastDay(s.plannedDate)).toList();
      if (activeSessions.length != allSessions.length) {
        saveStudySessions(activeSessions);
      }
      return activeSessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStudySessions(List<StudySession> list) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return;
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_getKey(_keyStudySessions), str);
  }

  // --- Grades ---
  List<CourseGrade> getCourseGrades() {
    final uid = _currentUserId;
    if (uid.isEmpty) return [];
    final raw = _prefs.getString(_getKey(_keyGrades));
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => CourseGrade.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCourseGrades(List<CourseGrade> list) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return;
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_getKey(_keyGrades), str);
  }

  // --- Holidays ---
  List<AcademicHoliday> getHolidays() {
    final uid = _currentUserId;
    if (uid.isEmpty) return [];
    final raw = _prefs.getString(_getKey(_keyHolidays));
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => AcademicHoliday.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHolidays(List<AcademicHoliday> list) async {
    final uid = _currentUserId;
    if (uid.isEmpty) return;
    final str = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_getKey(_keyHolidays), str);
  }
}

final productivityRepositoryProvider = Provider<ProductivityRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProductivityRepository(prefs, ref);
});
