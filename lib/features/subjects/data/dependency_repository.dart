import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/subjects/domain/subject_dependency_model.dart';

class DependencyRepository extends StateNotifier<List<SubjectDependency>> {
  static const String _keyDependencies = 'px_subject_dependencies_list';
  final SharedPreferences _prefs;
  final Ref? _ref;

  DependencyRepository(this._prefs, [this._ref]) : super([]) {
    _load();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keyDependencies;
    return '${effectiveUid}_$_keyDependencies';
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
            .map(
              (item) => SubjectDependency.fromMap(item as Map<String, dynamic>),
            )
            .where((d) => d.userId == uid || d.userId.isEmpty)
            .map((d) => d.userId != uid ? d.copyWith(userId: uid) : d)
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
    final jsonStr = jsonEncode(state.map((d) => d.toMap()).toList());
    await _prefs.setString(key, jsonStr);
  }

  bool causesCycle(String subjectId, String requiredSubjectId) {
    if (subjectId == requiredSubjectId) return true;

    final visited = <String>{};
    bool dfs(String current) {
      if (current == subjectId) return true;
      if (visited.contains(current)) return false;
      visited.add(current);

      final currentDeps = state.where((dep) => dep.subjectId == current);
      for (final dep in currentDeps) {
        if (dfs(dep.requiredSubjectId)) return true;
      }
      return false;
    }

    return dfs(requiredSubjectId);
  }

  static bool hasCycleStatic({
    required String subjectId,
    required String requiredSubjectId,
    required List<SubjectDependency> dependencies,
  }) {
    if (subjectId == requiredSubjectId) return true;

    final visited = <String>{};
    bool dfs(String current) {
      if (current == subjectId) return true;
      if (visited.contains(current)) return false;
      visited.add(current);

      final currentDeps = dependencies.where((dep) => dep.subjectId == current);
      for (final dep in currentDeps) {
        if (dfs(dep.requiredSubjectId)) return true;
      }
      return false;
    }

    return dfs(requiredSubjectId);
  }

  Future<String?> addDependency({
    required String subjectId,
    required String requiredSubjectId,
    required String type,
    String? minimumGrade,
    String? notes,
  }) async {
    if (subjectId == requiredSubjectId) {
      return 'A subject cannot depend on itself.';
    }

    // Check duplicate
    final isDuplicate = state.any(
      (dep) =>
          dep.subjectId == subjectId &&
          dep.requiredSubjectId == requiredSubjectId,
    );
    if (isDuplicate) {
      return 'This dependency already exists.';
    }

    // Cycle detection
    if (causesCycle(subjectId, requiredSubjectId)) {
      return 'Circular dependency detected.';
    }

    final uid = _currentUserId.isNotEmpty ? _currentUserId : 'user';
    final newDep = SubjectDependency(
      id: 'dep-${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      subjectId: subjectId,
      requiredSubjectId: requiredSubjectId,
      type: type,
      minimumGrade: minimumGrade,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [...state, newDep];
    await _save();
    return null;
  }

  Future<void> removeDependency(String id) async {
    state = state.where((dep) => dep.id != id).toList();
    await _save();
  }

  Future<void> removeDependenciesForSubject(String subjectId) async {
    state = state
        .where(
          (dep) =>
              dep.subjectId != subjectId && dep.requiredSubjectId != subjectId,
        )
        .toList();
    await _save();
  }

  Future<void> restore(List<SubjectDependency> list) async {
    state = list;
    await _save();
  }
}

// Providers
final dependencyRepositoryProvider =
    StateNotifierProvider<DependencyRepository, List<SubjectDependency>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return DependencyRepository(prefs, ref);
    });
