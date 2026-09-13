import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/widget_data_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';

class ClassSubstituteRepository extends StateNotifier<Map<String, String>> {
  static const String _keyDailySubstitutes = 'daily_timetable_substitutes';
  final SharedPreferences _prefs;
  final Ref? _ref;

  ClassSubstituteRepository(this._prefs, [this._ref]) : super({}) {
    _init();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keyDailySubstitutes;
    return '${effectiveUid}_$_keyDailySubstitutes';
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

  static String buildKey(DateTime date, String entryId) {
    return '${DateFormat('yyyyMMdd').format(date)}_$entryId';
  }

  void _load() {
    final uid = _currentUserId;
    final key = _getKey(uid);
    var jsonStr = _prefs.getString(key);
    if (jsonStr == null && uid.isNotEmpty) {
      jsonStr = _prefs.getString(_keyDailySubstitutes);
    }
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        state = {};
      }
    } else {
      state = {};
    }
  }

  Future<void> _save() async {
    final uid = _currentUserId;
    final key = _getKey(uid);
    final jsonStr = jsonEncode(state);
    await _prefs.setString(key, jsonStr);
    if (uid.isNotEmpty) {
      await _prefs.setString(_keyDailySubstitutes, jsonStr);
    }
    _syncWidgets();
  }

  void _syncWidgets() {
    try {
      if (_ref != null) {
        _ref.read(widgetDataServiceProvider).syncWithAppData(_ref);
      }
    } catch (_) {}
  }

  Future<void> setSubstitute({
    required DateTime date,
    required String entryId,
    required String substituteSubjectId,
  }) async {
    final key = buildKey(date, entryId);
    state = {...state, key: substituteSubjectId};
    await _save();
  }

  Future<void> removeSubstitute({
    required DateTime date,
    required String entryId,
  }) async {
    final key = buildKey(date, entryId);
    if (!state.containsKey(key)) return;
    final updated = Map<String, String>.from(state)..remove(key);
    state = updated;
    await _save();
  }

  Future<void> removeSubstituteByKey(String key) async {
    if (!state.containsKey(key)) return;
    final updated = Map<String, String>.from(state)..remove(key);
    state = updated;
    await _save();
  }

  String? getSubstitute(DateTime date, String entryId) {
    final key = buildKey(date, entryId);
    return state[key];
  }

  Future<void> clearAll() async {
    state = {};
    await _save();
  }

  void reloadFromStorage() {
    _load();
  }
}

// Provider
final classSubstituteRepositoryProvider = StateNotifierProvider<
  ClassSubstituteRepository,
  Map<String, String>
>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ClassSubstituteRepository(prefs, ref);
});
