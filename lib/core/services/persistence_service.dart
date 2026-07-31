import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/models/user_profile.dart';

class PersistenceService {
  static const String _keyProfile = 'user_profile';
  static const String _keyToken = 'auth_token';

  final SharedPreferences _prefs;

  PersistenceService(this._prefs);

  Future<void> saveUserProfile(UserProfile profile) async {
    final jsonStr = jsonEncode(profile.toMap());
    await _prefs.setString(_keyProfile, jsonStr);
  }

  UserProfile? getUserProfile() {
    final jsonStr = _prefs.getString(_keyProfile);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAuthToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  String? getAuthToken() {
    return _prefs.getString(_keyToken);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyProfile);
  }
}
