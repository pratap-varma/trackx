import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/hive_db_service.dart';
import 'package:trackx/core/services/sync_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/features/timetable/data/services/notification_service.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

class TimetableRepository extends StateNotifier<List<TimetableEntry>> {
  static const String _keyTimetable = 'timetable_entries_list';
  final SharedPreferences _prefs;
  final Ref? _ref;

  TimetableRepository(this._prefs, [this._ref]) : super([]) {
    _init();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keyTimetable;
    return '${effectiveUid}_$_keyTimetable';
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
      jsonStr = _prefs.getString(_keyTimetable);
    }
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => TimetableEntry.fromMap(item as Map<String, dynamic>))
            .where(
              (e) =>
                  uid.isEmpty ||
                  e.userId == uid ||
                  e.userId.isEmpty ||
                  e.userId == 'guest' ||
                  e.userId == 'user' ||
                  e.userId == 'u1',
            )
            .map(
              (e) => (uid.isNotEmpty && e.userId != uid)
                  ? e.copyWith(userId: uid)
                  : e,
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
          final box = db.getBoxOrNull(HiveDbService.boxTimetable);
          if (box != null && box.isNotEmpty) {
            final hiveEntries = box.values
                .map(
                  (e) => TimetableEntry.fromMap(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .where(
                  (e) =>
                      uid.isEmpty ||
                      e.userId == uid ||
                      e.userId.isEmpty ||
                      e.userId == 'guest' ||
                      e.userId == 'user' ||
                      e.userId == 'u1',
                )
                .toList();
            if (hiveEntries.isNotEmpty) {
              state = hiveEntries;
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
    final jsonStr = jsonEncode(state.map((e) => e.toMap()).toList());
    await _prefs.setString(key, jsonStr);
    if (uid.isNotEmpty) {
      await _prefs.setString(_keyTimetable, jsonStr);
    }

    // Save to Hive Database
    try {
      final db = _ref?.read(hiveDbServiceProvider);
      if (db != null) {
        final box = db.getBoxOrNull(HiveDbService.boxTimetable);
        if (box != null) {
          for (final entry in state) {
            await box.put(entry.id, entry.toMap());
          }
        }
      }
    } catch (_) {}

    _syncNotifications();
  }

  void _syncNotifications() {
    try {
      final notifService = _ref?.read(notificationServiceProvider);
      final globalTarget =
          _ref?.read(authRepositoryProvider).userProfile?.globalTarget ?? 75.0;
      notifService?.scheduleReminders(state, globalTarget);
    } catch (_) {}
  }

  /// Conflict prevention rules:
  /// - Overlapping class times on the same day
  /// - Two subjects assigned to the same day and period
  String? verifyConflict(TimetableEntry entry) {
    if (!entry.isValidRange) {
      return 'End time must be after start time.';
    }

    final duplicates = state.where(
      (e) =>
          e.id != entry.id &&
          e.semesterId == entry.semesterId &&
          e.dayOfWeek == entry.dayOfWeek &&
          e.isEnabled,
    );

    for (final other in duplicates) {
      // Period duplication check
      if (other.periodNumber == entry.periodNumber) {
        return 'Period ${entry.periodNumber} is already occupied on this day.';
      }

      // Time overlap check
      final overlap =
          entry.startTime < other.endTime && entry.endTime > other.startTime;
      if (overlap) {
        return 'Time overlaps with scheduled class (${other.startTimeDisplay} - ${other.endTimeDisplay}).';
      }
    }

    return null;
  }

  Future<String?> addEntry(TimetableEntry entry) async {
    final uid = _currentUserId.isNotEmpty ? _currentUserId : 'user';
    final userScopedEntry = entry.userId != uid
        ? entry.copyWith(userId: uid)
        : entry;

    final conflictMsg = verifyConflict(userScopedEntry);
    if (conflictMsg != null) return conflictMsg;

    state = [...state, userScopedEntry];
    await _save();

    try {
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue('timetable', userScopedEntry.id, 'create', userScopedEntry.toMap());
    } catch (_) {}

    return null;
  }

  Future<String?> updateEntry(TimetableEntry entry) async {
    final conflictMsg = verifyConflict(entry);
    if (conflictMsg != null) return conflictMsg;

    final updatedEntry = entry.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    state = state.map((e) => e.id == entry.id ? updatedEntry : e).toList();
    await _save();

    try {
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue('timetable', updatedEntry.id, 'update', updatedEntry.toMap());
    } catch (_) {}

    return null;
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();

    try {
      final db = _ref?.read(hiveDbServiceProvider);
      db?.getBoxOrNull(HiveDbService.boxTimetable)?.delete(id);
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue('timetable', id, 'delete', {'id': id});
    } catch (_) {}
  }

  Future<void> setEnabled(String id, bool enabled) async {
    state = state.map((e) {
      if (e.id == id) {
        return e.copyWith(
          isEnabled: enabled,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return e;
    }).toList();
    await _save();
  }

  Future<void> copyDay(String semesterId, int fromDay, int toDay) async {
    final sourceEntries = state
        .where((e) => e.semesterId == semesterId && e.dayOfWeek == fromDay)
        .toList();

    // Clear destination day first
    await clearDay(semesterId, toDay);

    final uid = _currentUserId.isNotEmpty ? _currentUserId : 'user';
    final copied = sourceEntries.map((e) {
      return TimetableEntry(
        id: 'entry-${DateTime.now().millisecondsSinceEpoch}-${e.periodNumber}',
        userId: uid,
        semesterId: e.semesterId,
        subjectId: e.subjectId,
        dayOfWeek: toDay,
        periodNumber: e.periodNumber,
        startTime: e.startTime,
        endTime: e.endTime,
        room: e.room,
        notes: e.notes,
        isEnabled: e.isEnabled,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }).toList();

    state = [...state, ...copied];
    await _save();
  }

  Future<void> clearDay(String semesterId, int day) async {
    state = state
        .where((e) => !(e.semesterId == semesterId && e.dayOfWeek == day))
        .toList();
    await _save();
  }

  Future<void> clearSemester(String semesterId) async {
    state = state.where((e) => e.semesterId != semesterId).toList();
    await _save();
  }

  Future<void> deleteEntriesForSubject(String subjectId) async {
    state = state.where((e) => e.subjectId != subjectId).toList();
    await _save();
  }
}

// Provider
final timetableRepositoryProvider =
    StateNotifierProvider<TimetableRepository, List<TimetableEntry>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return TimetableRepository(prefs, ref);
    });
