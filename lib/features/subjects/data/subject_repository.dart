import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';

class SubjectRepository extends StateNotifier<List<Subject>> {
  static const String _keySubjects = 'subjects_list';
  final SharedPreferences _prefs;

  SubjectRepository(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_keySubjects);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => Subject.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(state.map((s) => s.toMap()).toList());
    await _prefs.setString(_keySubjects, jsonStr);
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

    final sub = Subject(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_1',
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
      return SubjectRepository(prefs);
    });
