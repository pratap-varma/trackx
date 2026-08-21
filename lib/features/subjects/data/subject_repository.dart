import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/features/subjects/data/dependency_repository.dart';
import 'package:trackx/features/subjects/data/topic_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';

class SubjectRepository extends StateNotifier<List<Subject>> {
  static const String _keySubjects = 'subjects_list';
  final SharedPreferences _prefs;
  final Ref? _ref;

  SubjectRepository(this._prefs, [this._ref]) : super([]) {
    _init();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keySubjects;
    return '${effectiveUid}_$_keySubjects';
  }

  void _init() {
    _load();
    _ref?.listen<AuthState>(authRepositoryProvider, (previous, next) {
      if (previous?.userProfile?.id != next.userProfile?.id ||
          previous?.status != next.status) {
        _load();
      }
    });
  }

  void _load() {
    final uid = _currentUserId;
    if (uid.isEmpty) {
      state = [];
      return;
    }
    final key = _getKey(uid);
    final jsonStr = _prefs.getString(key);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => Subject.fromMap(item as Map<String, dynamic>))
            .where((s) => s.userId == uid || s.userId.isEmpty)
            .map((s) => s.userId != uid ? s.copyWith(userId: uid) : s)
            .toList();
      } catch (_) {
        state = [];
      }
    } else {
      state = [];
    }
  }

  Future<void> _save() async {
    final uid = _currentUserId;
    if (uid.isEmpty) return;
    final key = _getKey(uid);
    final jsonStr = jsonEncode(state.map((s) => s.toMap()).toList());
    await _prefs.setString(key, jsonStr);
  }

  Future<bool> addSubject(
    String semesterId,
    String name,
    String faculty,
    int color,
    double? targetOverride, {
    String? code,
    String? type,
    double? credits,
    int? weeklyPeriods,
    String? expectedDifficulty,
    String? status,
  }) async {
    // Prevent duplicate active subjects with the same name in the same semester
    final isDuplicate = state.any(
      (s) =>
          s.semesterId == semesterId &&
          s.name.toLowerCase() == name.trim().toLowerCase() &&
          s.status != 'Archived',
    );

    if (isDuplicate) return false;

    final uid = _currentUserId.isNotEmpty ? _currentUserId : 'user';

    final sub = Subject(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      semesterId: semesterId,
      name: name,
      code: code,
      facultyName: faculty,
      colorValue: color,
      type: type ?? 'Theory',
      credits: credits,
      weeklyPeriods: weeklyPeriods,
      targetAttendance: targetOverride ?? 75.0,
      presentClasses: 0,
      absentClasses: 0,
      status: status ?? 'Active',
      expectedDifficulty: expectedDifficulty ?? 'Not Set',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = [...state, sub];
    await _save();
    return true;
  }

  Future<void> editSubject(
    String id,
    String name,
    String faculty,
    int color,
    double? targetOverride, {
    String? code,
    String? type,
    double? credits,
    int? weeklyPeriods,
    String? expectedDifficulty,
    String? grade,
    double? marks,
    String? status,
  }) async {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(
          name: name,
          facultyName: faculty,
          colorValue: color,
          targetAttendance: targetOverride ?? s.targetAttendance,
          code: code ?? s.code,
          type: type ?? s.type,
          credits: credits ?? s.credits,
          weeklyPeriods: weeklyPeriods ?? s.weeklyPeriods,
          expectedDifficulty: expectedDifficulty ?? s.expectedDifficulty,
          grade: grade ?? s.grade,
          marks: marks ?? s.marks,
          status: status ?? s.status,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return s;
    }).toList();
    await _save();
  }

  Future<void> deleteSubject(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _save();
    try {
      _ref
          ?.read(timetableRepositoryProvider.notifier)
          .deleteEntriesForSubject(id);
      _ref
          ?.read(attendanceRepositoryProvider.notifier)
          .deleteRecordsForSubject(id);
      _ref?.read(topicRepositoryProvider.notifier).deleteTopicsForSubject(id);
      _ref
          ?.read(dependencyRepositoryProvider.notifier)
          .removeDependenciesForSubject(id);
    } catch (_) {}
  }

  Future<void> archiveSubject(String id) async {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(
          status: 'Archived',
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return s;
    }).toList();
    await _save();
  }

  Future<void> restoreSubject(String id) async {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(
          status: 'Active',
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return s;
    }).toList();
    await _save();
  }

  Future<void> restore(List<Subject> list) async {
    state = list;
    await _save();
  }
}

// Provider
final subjectRepositoryProvider =
    StateNotifierProvider<SubjectRepository, List<Subject>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SubjectRepository(prefs, ref);
    });
