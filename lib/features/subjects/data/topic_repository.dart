import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/subjects/domain/topic_model.dart';

class TopicRepository extends StateNotifier<List<Topic>> {
  static const String _keyTopics = 'px_syllabus_topics_list';
  final SharedPreferences _prefs;

  TopicRepository(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_keyTopics);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => Topic.fromMap(item as Map<String, dynamic>))
            .toList();
        // Sort by order
        state.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(state.map((t) => t.toMap()).toList());
    await _prefs.setString(_keyTopics, jsonStr);
  }

  Future<void> createTopic({
    required String subjectId,
    required String title,
    String? description,
    required String difficulty,
    required String confidence,
    required int estimatedMinutes,
  }) async {
    final newId = 'top-${DateTime.now().millisecondsSinceEpoch}';
    final count = state.where((t) => t.subjectId == subjectId).length;
    final topic = Topic(
      id: newId,
      userId: 'user_1',
      subjectId: subjectId,
      title: title,
      description: description,
      status: 'Not Started',
      difficulty: difficulty,
      confidence: confidence,
      estimatedMinutes: estimatedMinutes,
      completedMinutes: 0,
      sortOrder: count,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [...state, topic];
    await _save();
  }

  Future<void> updateTopic(Topic topic) async {
    state = state.map((t) => t.id == topic.id ? topic.copyWith(updatedAt: DateTime.now()) : t).toList();
    await _save();
  }

  Future<void> deleteTopic(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _save();
  }

  Future<void> reorderTopics(List<String> topicIdsOrdered) async {
    state = state.map((t) {
      final index = topicIdsOrdered.indexOf(t.id);
      if (index != -1) {
        return t.copyWith(sortOrder: index);
      }
      return t;
    }).toList();
    state.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await _save();
  }

  Future<void> markCompleted(String id, {int? completedMinutes}) async {
    state = state.map((t) {
      if (t.id == id) {
        return t.copyWith(
          status: 'Completed',
          completedMinutes: completedMinutes ?? t.estimatedMinutes,
          lastReviewedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return t;
    }).toList();
    await _save();
  }

  Future<void> restore(List<Topic> list) async {
    state = list;
    await _save();
  }
}

// Providers
final topicRepositoryProvider =
    StateNotifierProvider<TopicRepository, List<Topic>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TopicRepository(prefs);
});
