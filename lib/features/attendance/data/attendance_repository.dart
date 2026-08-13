import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';

class AttendanceRepository extends StateNotifier<List<AttendanceRecord>> {
  static const String _keyAttendance = 'attendance_records_list';
  final SharedPreferences _prefs;

  AttendanceRepository(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_keyAttendance);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map(
              (item) => AttendanceRecord.fromMap(item as Map<String, dynamic>),
            )
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(state.map((r) => r.toMap()).toList());
    await _prefs.setString(_keyAttendance, jsonStr);
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
    // Check if attendance record already exists for this User, Subject, Date, Period
    final existingIndex = state.indexWhere(
      (r) =>
          r.userId == userId &&
          r.subjectId == subjectId &&
          r.semesterId == semesterId &&
          r.periodNumber == periodNumber &&
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day,
    );

    if (existingIndex != -1) {
      // Update existing record
      final existing = state[existingIndex];
      final updated = existing.copyWith(
        status: status,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
      await _save();
      return null;
    }

    final record = AttendanceRecord(
      id: 'att-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
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
    return null;
  }

  Future<void> deleteAttendance(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _save();
  }

  // Restore/Undo support helper
  Future<void> insertRecord(AttendanceRecord record) async {
    state = [...state, record];
    await _save();
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
      return AttendanceRepository(prefs);
    });
