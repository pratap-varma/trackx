import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/hive_db_service.dart';
import 'package:trackx/core/services/sync_service.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/core/services/widget_data_service.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';

class AttendanceRepository extends StateNotifier<List<AttendanceRecord>> {
  static const String _keyAttendance = 'attendance_records_list';
  final SharedPreferences _prefs;
  final Ref? _ref;

  AttendanceRepository(this._prefs, [this._ref]) : super([]) {
    _init();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keyAttendance;
    return '${effectiveUid}_$_keyAttendance';
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
      jsonStr = _prefs.getString(_keyAttendance);
    }

    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map(
              (item) => AttendanceRecord.fromMap(item as Map<String, dynamic>),
            )
            .where(
              (r) =>
                  uid.isEmpty ||
                  r.userId == uid ||
                  r.userId.isEmpty ||
                  r.userId == 'guest' ||
                  r.userId == 'user' ||
                  r.userId == 'u1',
            )
            .map(
              (r) => (uid.isNotEmpty && r.userId != uid)
                  ? r.copyWith(userId: uid)
                  : r,
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
          final box = db.getBoxOrNull(HiveDbService.boxAttendance);
          if (box != null && box.isNotEmpty) {
            final hiveRecords = box.values
                .map(
                  (e) => AttendanceRecord.fromMap(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .where(
                  (r) =>
                      uid.isEmpty ||
                      r.userId == uid ||
                      r.userId.isEmpty ||
                      r.userId == 'guest' ||
                      r.userId == 'user' ||
                      r.userId == 'u1',
                )
                .toList();
            if (hiveRecords.isNotEmpty) {
              state = hiveRecords;
            }
          }
        }
      } catch (_) {}
    }

    // Sync counts with Subject repository
    _syncSubjectAttendanceCounts();
  }

  void reloadFromStorage() {
    _load();
  }

  Future<void> _save() async {
    final uid = _currentUserId;
    final key = _getKey(uid);
    final jsonStr = jsonEncode(state.map((r) => r.toMap()).toList());
    await _prefs.setString(key, jsonStr);
    if (uid.isNotEmpty) {
      await _prefs.setString(_keyAttendance, jsonStr);
    }

    // Save to Hive Database
    try {
      final db = _ref?.read(hiveDbServiceProvider);
      if (db != null) {
        final box = db.getBoxOrNull(HiveDbService.boxAttendance);
        if (box != null) {
          for (final rec in state) {
            await box.put(rec.id, rec.toMap());
          }
        }
      }
    } catch (_) {}

    _syncSubjectAttendanceCounts();
    try {
      _ref?.read(widgetDataServiceProvider).syncWithAppData(_ref);
    } catch (_) {}
  }

  void _syncSubjectAttendanceCounts() {
    try {
      _ref?.read(subjectRepositoryProvider.notifier).syncAttendanceCounts(state);
    } catch (_) {}
  }

  /// 24-hour editing rule
  static bool canEditAttendance(AttendanceRecord record, DateTime currentTime) {
    final difference = currentTime.difference(record.date);
    return difference.inHours.abs() <= 24;
  }

  /// Mark/Create attendance
  Future<String?> markAttendance({
    required String userId,
    required String semesterId,
    required String subjectId,
    required DateTime date,
    int? periodNumber,
    required String status,
  }) async {
    final effectiveUserId = userId.isNotEmpty
        ? userId
        : (_currentUserId.isNotEmpty ? _currentUserId : 'user');

    // Check if attendance record already exists for this User, Subject, Date, Period
    final existingIndex = state.indexWhere(
      (r) =>
          r.subjectId == subjectId &&
          r.semesterId == semesterId &&
          (periodNumber == null || r.periodNumber == periodNumber) &&
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day,
    );

    if (existingIndex != -1) {
      // Update existing record
      final existing = state[existingIndex];
      final updated = existing.copyWith(
        status: status,
        periodNumber: periodNumber ?? existing.periodNumber,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
      await _save();

      try {
        final syncService = _ref?.read(syncServiceProvider);
        syncService?.addToQueue(
          'attendance',
          updated.id,
          'update',
          updated.toMap(),
        );
      } catch (_) {}

      return null;
    }

    final record = AttendanceRecord(
      id: 'att-${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().microsecond}',
      userId: effectiveUserId,
      semesterId: semesterId,
      subjectId: subjectId,
      date: date,
      periodNumber: periodNumber,
      status: status,
      source: 'manual',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = [...state, record];
    await _save();

    try {
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue(
        'attendance',
        record.id,
        'create',
        record.toMap(),
      );
    } catch (_) {}

    return null;
  }

  Future<String?> editAttendance(
    String id,
    String newStatus,
    DateTime currentTime,
  ) async {
    final index = state.indexWhere((r) => r.id == id);
    if (index == -1) return 'Record not found.';

    final record = state[index];
    if (!canEditAttendance(record, currentTime)) {
      return 'Editing period expired. Locked after 24 hours.';
    }

    final updated = record.copyWith(
      status: newStatus,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = [...state.sublist(0, index), updated, ...state.sublist(index + 1)];
    await _save();

    try {
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue(
        'attendance',
        updated.id,
        'update',
        updated.toMap(),
      );
    } catch (_) {}

    return null;
  }

  Future<void> deleteAttendance(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _save();

    try {
      final db = _ref?.read(hiveDbServiceProvider);
      db?.getBoxOrNull(HiveDbService.boxAttendance)?.delete(id);
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue('attendance', id, 'delete', {'id': id});
    } catch (_) {}
  }

  Future<void> deleteRecordsForSubject(String subjectId) async {
    final toDelete = state.where((r) => r.subjectId == subjectId).toList();
    state = state.where((r) => r.subjectId != subjectId).toList();
    await _save();

    try {
      final db = _ref?.read(hiveDbServiceProvider);
      final syncService = _ref?.read(syncServiceProvider);
      for (final r in toDelete) {
        db?.getBoxOrNull(HiveDbService.boxAttendance)?.delete(r.id);
        syncService?.addToQueue('attendance', r.id, 'delete', {'id': r.id});
      }
    } catch (_) {}
  }

  // Restore/Undo support helper
  Future<void> insertRecord(AttendanceRecord record) async {
    state = [...state, record];
    await _save();

    try {
      final syncService = _ref?.read(syncServiceProvider);
      syncService?.addToQueue(
        'attendance',
        record.id,
        'create',
        record.toMap(),
      );
    } catch (_) {}
  }

  Future<void> restore(List<AttendanceRecord> list) async {
    state = list;
    await _save();
  }
}

// Provider
final attendanceRepositoryProvider =
    StateNotifierProvider<AttendanceRepository, List<AttendanceRecord>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return AttendanceRepository(prefs, ref);
    });
