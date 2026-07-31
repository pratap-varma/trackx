import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/domain/semester_scenario_model.dart';

class ScenarioRepository extends StateNotifier<List<SemesterScenario>> {
  static const String _keyScenarios = 'px_semester_scenarios_list';
  final SharedPreferences _prefs;

  ScenarioRepository(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_keyScenarios);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => SemesterScenario.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(state.map((s) => s.toMap()).toList());
    await _prefs.setString(_keyScenarios, jsonStr);
  }

  Future<void> createScenario({
    required String name,
    required String programmeId,
    String? semesterId,
    required List<String> plannedSubjectIds,
    required double totalCredits,
    required double estimatedWeeklyStudyHours,
  }) async {
    final newId = 'scen-${DateTime.now().millisecondsSinceEpoch}';
    final scen = SemesterScenario(
      id: newId,
      userId: 'user_1',
      programmeId: programmeId,
      name: name,
      semesterId: semesterId,
      plannedSubjectIds: plannedSubjectIds,
      totalCredits: totalCredits,
      estimatedWeeklyStudyHours: estimatedWeeklyStudyHours,
      status: 'Draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [...state, scen];
    await _save();
  }

  Future<void> duplicateScenario(String id, String newName) async {
    final target = state.firstWhere((s) => s.id == id);
    final dup = target.copyWith(
      id: 'scen-${DateTime.now().millisecondsSinceEpoch}',
      name: newName,
      status: 'Draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [...state, dup];
    await _save();
  }

  Future<void> renameScenario(String id, String newName) async {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
    await _save();
  }

  Future<void> updateScenario(SemesterScenario scenario) async {
    state = state.map((s) => s.id == scenario.id ? scenario.copyWith(updatedAt: DateTime.now()) : s).toList();
    await _save();
  }

  Future<void> markPreferred(String id) async {
    final target = state.firstWhere((s) => s.id == id);
    final progId = target.programmeId;

    state = state.map((s) {
      if (s.programmeId == progId) {
        return s.copyWith(
          status: s.id == id ? 'Preferred' : (s.status == 'Preferred' ? 'Draft' : s.status),
          updatedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
    await _save();
  }

  Future<void> archiveScenario(String id) async {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(
          status: 'Archived',
          updatedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
    await _save();
  }

  Future<void> restoreScenario(String id) async {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(
          status: 'Draft',
          updatedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
    await _save();
  }

  Future<void> deleteScenario(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _save();
  }

  Future<void> restore(List<SemesterScenario> list) async {
    state = list;
    await _save();
  }
}

// Providers
final scenarioRepositoryProvider =
    StateNotifierProvider<ScenarioRepository, List<SemesterScenario>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ScenarioRepository(prefs);
});
