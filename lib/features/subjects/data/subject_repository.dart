import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/hive_db_service.dart';
import 'package:trackx/core/services/sync_service.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
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
    final key = _getKey(uid);
    var jsonStr = _prefs.getString(key);
    if (jsonStr == null && uid.isNotEmpty) {
      jsonStr = _prefs.getString(_keySubjects);
    }

    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => Subject.fromMap(item as Map<String, dynamic>))
            .where(
              (s) =>
                  uid.isEmpty ||
                  s.userId == uid ||
                  s.userId.isEmpty ||
                  s.userId == 'guest' ||
                  s.userId == 'user' ||
                  s.userId == 'u1',
            )
            .map(
              (s) => (uid.isNotEmpty && s.userId != uid)
                  ? s.copyWith(userId: uid)
                  : s,
            )
            .toList();
      } catch (_) {
        state = [];
      }
    } else {
      // Fallback: check Hive Box if SharedPreferences is empty
      try {
        final db = _ref?.read(hiveDbServiceProvider);
        if (db != null) {
          final box = db.getBoxOrNull(HiveDbService.boxSubjects);
          if (box != null && box.isNotEmpty) {
            final hiveSubjects = box.values
                .map((e) => Subject.fromMap(Map<String, dynamic>.from(e as Map)))
                .where(
                  (s) =>
                      uid.isEmpty ||
                      s.userId == uid ||
                      s.userId.isEmpty ||
                      s.userId == 'guest' ||
                      s.userId == 'user' ||
                      s.userId == 'u1',
                )
                .toList();
            if (hiveSubjects.isNotEmpty) {
              state = hiveSubjects;
            }
          }
        }
      } catch (_) {}
    }
  }

  void reloadFromStorage() {
    _load();
  }

  Future<void> _save() async {
    final uid = _currentUserId;
    final key = _getKey(uid);
    final jsonStr = jsonEncode(state.map((s) => s.toMap()).toList());
    await _prefs.setString(key, jsonStr);
    if (uid.isNotEmpty) {
      await _prefs.setString(_keySubjects, jsonStr);
    }

    // Save to Hive Database
    try {
      final db = _ref?.read(hiveDbServiceProvider);
      if (db != null) {
        final box = db.getBoxOrNull(HiveDbService.boxSubjects);
        if (box != null) {
          for (final sub in state) {
            await box.put(sub.id, sub.toMap());
          }
        }
      }
    } catch (_) {}
  }

  void syncAttendanceCounts(List<AttendanceRecord> records) {
    if (state.isEmpty) return;
    bool hasChanges = false;
    final updatedList = state.map((sub) {
      final subRecords = records.where((r) => r.subjectId == sub.id).toList();
      final present = subRecords.where((r) => r.status == 'present').length;
      final total = subRecords.length;
      final absent = total - present;
      if (sub.presentClasses != present || sub.absentClasses != absent) {
        hasChanges = true;
        return sub.copyWith(
          presentClasses: present,
          absentClasses: absent,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return sub;
    }).toList();

    if (hasChanges) {
      state = updatedList;
      _save();
    }
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
      id: 'sub-${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().microsecond}',
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

    try {
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue('subject', sub.id, 'create', sub.toMap());
    } catch (_) {}

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
    Subject? updatedSubject;
    state = state.map((s) {
      if (s.id == id) {
        updatedSubject = s.copyWith(
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
        return updatedSubject!;
      }
      return s;
    }).toList();
    await _save();

    if (updatedSubject != null) {
      try {
        final syncService = _ref?.read(syncServiceProvider);
        syncService?.addToQueue(
          'subject',
          updatedSubject!.id,
          'update',
          updatedSubject!.toMap(),
        );
      } catch (_) {}
    }
  }

  Future<void> deleteSubject(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _save();

    try {
      final db = _ref?.read(hiveDbServiceProvider);
      db?.getBoxOrNull(HiveDbService.boxSubjects)?.delete(id);
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue('subject', id, 'delete', {'id': id});
    } catch (_) {}

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
