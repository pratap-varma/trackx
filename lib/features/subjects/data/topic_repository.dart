import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/subjects/domain/topic_model.dart';

class TopicRepository extends StateNotifier<List<Topic>> {
  static const String _keyTopics = 'px_syllabus_topics_list';
  final SharedPreferences _prefs;
  final Ref? _ref;

  TopicRepository(this._prefs, [this._ref]) : super([]) {
    _load();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keyTopics;
    return '${effectiveUid}_$_keyTopics';
  }

  void _load() {
    final uid = _currentUserId;
    if (uid.isEmpty) {
      state = [];
      return;
    }
    final key = _getKey(uid);
    final jsonStr = _prefs.getString(key);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => Topic.fromMap(item as Map<String, dynamic>))
            .where((t) => t.userId == uid || t.userId.isEmpty)
            .map((t) => t.userId != uid ? t.copyWith(userId: uid) : t)
            .toList();
        // Sort by order
        state.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      } catch (_) {
        state = [];
      }
    } else {
      state = [];
    }
  }

  Future<void> _save() async {
    final uid = _currentUserId;
    if (uid.isEmpty) return;
    final key = _getKey(uid);
    final jsonStr = jsonEncode(state.map((t) => t.toMap()).toList());
    await _prefs.setString(key, jsonStr);
  }

  Future<void> createTopic({
    required String subjectId,
    required String title,
    String? description,
    required String difficulty,
    required String confidence,
    required int estimatedMinutes,
  }) async {
    final uid = _currentUserId.isNotEmpty ? _currentUserId : 'user';
    final newId = 'top-${DateTime.now().millisecondsSinceEpoch}';
    final count = state.where((t) => t.subjectId == subjectId).length;
    final topic = Topic(
      id: newId,
      userId: uid,
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
    state = state
        .map(
          (t) =>
              t.id == topic.id ? topic.copyWith(updatedAt: DateTime.now()) : t,
        )
        .toList();
    await _save();
  }

  Future<void> deleteTopic(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _save();
  }

  Future<void> deleteTopicsForSubject(String subjectId) async {
    state = state.where((t) => t.subjectId != subjectId).toList();
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
      return TopicRepository(prefs, ref);
    });
