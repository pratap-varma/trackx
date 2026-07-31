import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_action.dart';

class AiActionHistoryRepository {
  static const String _keyActionHistory = 'px_ai_action_history_list';
  final SharedPreferences _prefs;

  AiActionHistoryRepository(this._prefs);

  List<AiActionRecord> getActionRecords() {
    final jsonStr = _prefs.getString(_keyActionHistory);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => AiActionRecord.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveActionRecords(List<AiActionRecord> list) async {
    final jsonStr = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyActionHistory, jsonStr);
  }

  Future<void> addActionRecord(AiActionRecord record) async {
    final list = getActionRecords();
    list.add(record);
    await saveActionRecords(list);
  }

  Future<void> updateActionRecordStatus(String id, AiActionStatus status, {DateTime? confirmedAt}) async {
    final list = getActionRecords();
    final updated = list.map((e) {
      if (e.id == id) {
        return e.copyWith(status: status, confirmedAt: confirmedAt);
      }
      return e;
    }).toList();
    await saveActionRecords(updated);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_keyActionHistory);
  }
}
