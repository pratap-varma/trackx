import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';

class TimetableRepository extends StateNotifier<List<TimetableEntry>> {
  static const String _keyTimetable = 'timetable_entries_list';
  final SharedPreferences _prefs;

  TimetableRepository(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_keyTimetable);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => TimetableEntry.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(state.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyTimetable, jsonStr);
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
    final conflictMsg = verifyConflict(entry);
    if (conflictMsg != null) return conflictMsg;

    state = [...state, entry];
    await _save();
    return null;
  }

  Future<String?> updateEntry(TimetableEntry entry) async {
    final conflictMsg = verifyConflict(entry);
    if (conflictMsg != null) return conflictMsg;

    state = state.map((e) => e.id == entry.id ? entry : e).toList();
    await _save();
    return null;
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
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

    final copied = sourceEntries.map((e) {
      return TimetableEntry(
        id: 'entry-${DateTime.now().millisecondsSinceEpoch}-${e.periodNumber}',
        userId: e.userId,
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
}

// Provider
final timetableRepositoryProvider =
    StateNotifierProvider<TimetableRepository, List<TimetableEntry>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return TimetableRepository(prefs);
    });
