import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/programmes/domain/programme_model.dart';

class ProgrammeRepository extends StateNotifier<List<Programme>> {
  static const String _keyProgrammes = 'px_programmes_list';
  static const String _keyActiveProgId = 'px_active_programme_id';
  final SharedPreferences _prefs;
  final Ref? _ref;

  ProgrammeRepository(this._prefs, [this._ref]) : super([]) {
    _load();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keyProgrammes;
    return '${effectiveUid}_$_keyProgrammes';
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
            .map((item) => Programme.fromMap(item as Map<String, dynamic>))
            .where((p) => p.userId == uid || p.userId.isEmpty)
            .map((p) => p.userId != uid ? p.copyWith(userId: uid) : p)
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
    final jsonStr = jsonEncode(state.map((p) => p.toMap()).toList());
    await _prefs.setString(key, jsonStr);
  }

  String? getActiveProgrammeId() {
    return _prefs.getString(_keyActiveProgId);
  }

  Future<void> setActiveProgramme(String id) async {
    await _prefs.setString(_keyActiveProgId, id);
    // Automatically set status to 'Active' for the chosen one and ensure others are updated if needed
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(status: 'Active', updatedAt: DateTime.now());
      } else if (p.status == 'Active') {
        return p.copyWith(status: 'Paused', updatedAt: DateTime.now());
      }
      return p;
    }).toList();
    await _save();
  }

  Future<void> createProgramme({
    required String name,
    String? degreeType,
    String? branch,
    required int joiningYear,
    int? expectedGraduationYear,
    required int totalSemesters,
    double? totalCredits,
    required String gradingSystemId,
  }) async {
    final uid = _currentUserId.isNotEmpty ? _currentUserId : 'user';
    final newId = 'prog-${DateTime.now().millisecondsSinceEpoch}';
    final prog = Programme(
      id: newId,
      userId: uid,
      name: name,
      degreeType: degreeType,
      branch: branch,
      joiningYear: joiningYear,
      expectedGraduationYear: expectedGraduationYear,
      totalSemesters: totalSemesters,
      totalCredits: totalCredits,
      gradingSystemId: gradingSystemId,
      status: state.isEmpty ? 'Active' : 'Paused',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [...state, prog];
    await _save();

    if (state.length == 1) {
      await setActiveProgramme(newId);
    }
  }

  Future<void> updateProgramme(Programme updated) async {
    state = state
        .map(
          (p) => p.id == updated.id
              ? updated.copyWith(updatedAt: DateTime.now())
              : p,
        )
        .toList();
    await _save();
  }

  Future<void> archiveProgramme(String id) async {
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(status: 'Archived', updatedAt: DateTime.now());
      }
      return p;
    }).toList();
    await _save();

    // If we archived the active programme, set another one active
    final activeId = getActiveProgrammeId();
    if (activeId == id) {
      final fallback = state.firstWhere(
        (p) => p.status != 'Archived',
        orElse: () => state.first,
      );
      await setActiveProgramme(fallback.id);
    }
  }

  Future<void> restoreProgramme(String id) async {
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(status: 'Paused', updatedAt: DateTime.now());
      }
      return p;
    }).toList();
    await _save();
  }

  Future<void> deleteProgramme(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();

    final activeId = getActiveProgrammeId();
    if (activeId == id && state.isNotEmpty) {
      await setActiveProgramme(state.first.id);
    }
  }

  Future<void> restore(List<Programme> list) async {
    state = list;
    await _save();
  }
}

// Providers
final programmeRepositoryProvider =
    StateNotifierProvider<ProgrammeRepository, List<Programme>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ProgrammeRepository(prefs, ref);
    });

final activeProgrammeProvider = Provider<Programme?>((ref) {
  final list = ref.watch(programmeRepositoryProvider);
  final repo = ref.watch(programmeRepositoryProvider.notifier);
  final activeId = repo.getActiveProgrammeId();
  if (activeId != null) {
    final active = list.where((p) => p.id == activeId).toList();
    if (active.isNotEmpty) return active.first;
  }
  final activeList = list.where((p) => p.status == 'Active').toList();
  if (activeList.isNotEmpty) return activeList.first;
  return list.isNotEmpty ? list.first : null;
});
