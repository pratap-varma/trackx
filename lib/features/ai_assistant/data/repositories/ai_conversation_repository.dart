import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/ai_advisor/domain/models/ai_models.dart';

class AiConversationRepository {
  static const String _keyConversations = 'px_ai_conversations_list';
  static const String _keyMessagesPrefix = 'px_ai_messages_list_';

  final SharedPreferences _prefs;

  AiConversationRepository(this._prefs);

  List<AiConversation> getConversations() {
    final jsonStr = _prefs.getString(_keyConversations);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((e) => AiConversation.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversations(List<AiConversation> list) async {
    final jsonStr = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyConversations, jsonStr);
  }

  List<AiMessage> getMessages(String conversationId) {
    final jsonStr = _prefs.getString('$_keyMessagesPrefix$conversationId');
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((e) => AiMessage.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(
    String conversationId,
    List<AiMessage> messages,
  ) async {
    final jsonStr = jsonEncode(messages.map((e) => e.toMap()).toList());
    await _prefs.setString('$_keyMessagesPrefix$conversationId', jsonStr);
  }

  Future<void> deleteConversation(String conversationId) async {
    final list = getConversations();
    final updated = list.where((e) => e.id != conversationId).toList();
    await saveConversations(updated);
    await _prefs.remove('$_keyMessagesPrefix$conversationId');
  }

  Future<void> clearAllHistory() async {
    final list = getConversations();
    for (final c in list) {
      await _prefs.remove('$_keyMessagesPrefix${c.id}');
    }
    await _prefs.remove(_keyConversations);
  }
}
