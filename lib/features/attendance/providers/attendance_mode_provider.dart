import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';

class AttendanceModeNotifier extends StateNotifier<String> {
  static const String _keyMode = 'attendance_mode_pref';
  final SharedPreferences _prefs;

  AttendanceModeNotifier(this._prefs) : super('subject') {
    final saved = _prefs.getString(_keyMode);
    if (saved != null) {
      state = saved;
    }
  }

  void setMode(String newMode) {
    state = newMode;
    _prefs.setString(_keyMode, newMode);
  }
}

final attendanceModeProvider =
    StateNotifierProvider<AttendanceModeNotifier, String>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return AttendanceModeNotifier(prefs);
    });
