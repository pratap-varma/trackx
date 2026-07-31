import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';

class SemesterRepository extends StateNotifier<List<Semester>> {
  static const String _keySemesters = 'semesters_list';
  final SharedPreferences _prefs;

  SemesterRepository(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_keySemesters);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => Semester.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(state.map((s) => s.toMap()).toList());
    await _prefs.setString(_keySemesters, jsonStr);
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
    final hasActiveInProg = state.any((sem) => sem.programmeId == progId && sem.status == 'Active');

    final newSem = Semester(
      id: 'sem-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_1',
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
  }

  Future<void> updateSemester(Semester updated) async {
    state = state.map((sem) => sem.id == updated.id ? updated.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch) : sem).toList();
    await _save();
  }

  Future<void> setActiveSemester(String id) async {
    final targetSem = state.firstWhere((s) => s.id == id, orElse: () => state.first);
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
  return SemesterRepository(prefs);
});

final activeSemesterProvider = Provider<Semester?>((ref) {
  final list = ref.watch(semesterRepositoryProvider);
  final active = list.where((sem) => sem.isActive).toList();
  return active.isNotEmpty ? active.first : (list.isNotEmpty ? list.first : null);
});

