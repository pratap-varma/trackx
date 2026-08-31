import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/hive_db_service.dart';
import 'package:trackx/core/services/sync_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';

class SemesterRepository extends StateNotifier<List<Semester>> {
  static const String _keySemesters = 'semesters_list';
  final SharedPreferences _prefs;
  final Ref? _ref;

  SemesterRepository(this._prefs, [this._ref]) : super([]) {
    _init();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keySemesters;
    return '${effectiveUid}_$_keySemesters';
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
      jsonStr = _prefs.getString(_keySemesters);
    }
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => Semester.fromMap(item as Map<String, dynamic>))
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
      // Fallback: check Hive Box if SharedPreferences is empty (e.g. fresh install after cloud pull)
      try {
        final db = _ref?.read(hiveDbServiceProvider);
        if (db != null) {
          final box = db.getBoxOrNull(HiveDbService.boxSemesters);
          if (box != null && box.isNotEmpty) {
            final hiveSemesters = box.values
                .map((e) => Semester.fromMap(Map<String, dynamic>.from(e as Map)))
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
            if (hiveSemesters.isNotEmpty) {
              state = hiveSemesters;
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
      await _prefs.setString(_keySemesters, jsonStr);
    }

    // Save to Hive Database
    try {
      final db = _ref?.read(hiveDbServiceProvider);
      if (db != null) {
        final box = db.getBoxOrNull(HiveDbService.boxSemesters);
        if (box != null) {
          for (final sem in state) {
            await box.put(sem.id, sem.toMap());
          }
        }
      }
    } catch (_) {}
  }

  Future<void> createSemester(
    String name,
    int? number,
    DateTime start,
    DateTime? end, {
    String? programmeId,
    String? academicYear,
    double? plannedCredits,
    double? completedCredits,
    double? attendanceTarget,
    String? notes,
    String? status,
  }) async {
    final progId = programmeId ?? '';
    final hasActiveInProg = state.any(
      (sem) => sem.programmeId == progId && sem.status == 'Active',
    );
    final uid = _currentUserId.isNotEmpty ? _currentUserId : 'user';

    final newSem = Semester(
      id: 'sem-${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().microsecond}',
      userId: uid,
      programmeId: progId,
      name: name,
      semesterNumber: number ?? 1,
      academicYear: academicYear ?? '${start.year}-${start.year + 1}',
      startDate: start,
      endDate: end,
      status: status ?? (!hasActiveInProg ? 'Active' : 'Upcoming'),
      plannedCredits: plannedCredits ?? 0.0,
      completedCredits: completedCredits ?? 0.0,
      attendanceTarget: attendanceTarget ?? 75.0,
      notes: notes ?? '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = [...state, newSem];
    await _save();

    // Push to cloud sync queue
    try {
      _ref
          ?.read(syncServiceProvider)
          .addToQueue('semester', newSem.id, 'create', newSem.toMap());
    } catch (_) {}
  }

  Future<void> updateSemester(Semester updated) async {
    final semWithUpdatedTime = updated.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    state = state
        .map(
          (sem) => sem.id == updated.id ? semWithUpdatedTime : sem,
        )
        .toList();
    await _save();

    try {
      _ref
          ?.read(syncServiceProvider)
          .addToQueue('semester', semWithUpdatedTime.id, 'update', semWithUpdatedTime.toMap());
    } catch (_) {}
  }

  Future<void> setActiveSemester(String id) async {
    final targetSem = state.firstWhere(
      (s) => s.id == id,
      orElse: () => state.first,
    );
    final progId = targetSem.programmeId;

    state = state.map((sem) {
      if (sem.programmeId == progId) {
        return sem.copyWith(
          status: sem.id == id ? 'Active' : 'Completed',
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return sem;
    }).toList();
    await _save();
  }

  Future<void> completeSemester(String id, {double? completedCredits}) async {
    state = state.map((sem) {
      if (sem.id == id) {
        return sem.copyWith(
          status: 'Completed',
          completedCredits: completedCredits ?? sem.plannedCredits,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return sem;
    }).toList();
    await _save();
  }

  Future<void> archiveSemester(String id) async {
    state = state.map((sem) {
      if (sem.id == id) {
        return sem.copyWith(
          status: 'Archived',
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return sem;
    }).toList();
    await _save();
  }

  Future<void> renameSemester(String id, String newName) async {
    state = state.map((sem) {
      if (sem.id == id) {
        return sem.copyWith(
          name: newName,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return sem;
    }).toList();
    await _save();
  }

  Future<void> deleteSemester(String id) async {
    state = state.where((sem) => sem.id != id).toList();
    // If we deleted the active semester and others exist in the same programme, make first active
    if (state.isNotEmpty && !state.any((sem) => sem.isActive)) {
      state = [state.first.copyWith(status: 'Active'), ...state.sublist(1)];
    }
    await _save();

    try {
      final db = _ref?.read(hiveDbServiceProvider);
      db?.getBoxOrNull(HiveDbService.boxSemesters)?.delete(id);
      _ref?.read(syncServiceProvider).addToQueue('semester', id, 'delete', {'id': id});
    } catch (_) {}
  }

  Future<void> restore(List<Semester> list) async {
    state = list;
    await _save();
  }
}

// Providers
final semesterRepositoryProvider =
    StateNotifierProvider<SemesterRepository, List<Semester>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SemesterRepository(prefs, ref);
    });

final activeSemesterProvider = Provider<Semester?>((ref) {
  final list = ref.watch(semesterRepositoryProvider);
  final active = list.where((sem) => sem.isActive).toList();
  return active.isNotEmpty
      ? active.first
      : (list.isNotEmpty ? list.first : null);
});
