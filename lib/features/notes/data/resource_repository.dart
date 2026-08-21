import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/notes/domain/models/academic_resource_model.dart';

class ResourceRepository extends StateNotifier<List<AcademicResource>> {
  static const String _keyResources = 'px_academic_resources_list';
  final SharedPreferences _prefs;
  final Ref? _ref;

  ResourceRepository(this._prefs, [this._ref]) : super([]) {
    _load();
  }

  String get _currentUserId =>
      _ref?.read(authRepositoryProvider).userProfile?.id ?? '';

  String _getKey([String? uid]) {
    final effectiveUid = uid ?? _currentUserId;
    if (effectiveUid.isEmpty) return _keyResources;
    return '${effectiveUid}_$_keyResources';
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
            .map(
              (item) => AcademicResource.fromMap(item as Map<String, dynamic>),
            )
            .where((r) => r.userId == uid || r.userId.isEmpty)
            .map((r) => r.userId != uid ? r.copyWith(userId: uid) : r)
            .toList();
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
    final jsonStr = jsonEncode(state.map((r) => r.toMap()).toList());
    await _prefs.setString(key, jsonStr);
  }

  Future<void> createResource({
    String? subjectId,
    String? topicId,
    required String title,
    required String type,
    String? url,
    String? localFilePath,
    String? cloudFileReference,
    String? description,
    required List<String> tags,
  }) async {
    final uid = _currentUserId.isNotEmpty ? _currentUserId : 'user';
    final newId = 'res-${DateTime.now().millisecondsSinceEpoch}';
    final resource = AcademicResource(
      id: newId,
      userId: uid,
      subjectId: subjectId,
      topicId: topicId,
      title: title,
      type: type,
      url: url,
      localFilePath: localFilePath,
      cloudFileReference: cloudFileReference,
      description: description,
      tags: tags,
      isFavorite: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [...state, resource];
    await _save();
  }

  Future<void> updateResource(AcademicResource resource) async {
    state = state
        .map(
          (r) => r.id == resource.id
              ? resource.copyWith(updatedAt: DateTime.now())
              : r,
        )
        .toList();
    await _save();
  }

  Future<void> toggleFavorite(String id) async {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(isFavorite: !r.isFavorite, updatedAt: DateTime.now());
      }
      return r;
    }).toList();
    await _save();
  }

  Future<void> deleteResource(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _save();
  }

  Future<void> restore(List<AcademicResource> list) async {
    state = list;
    await _save();
  }
}

// Providers
final resourceRepositoryProvider =
    StateNotifierProvider<ResourceRepository, List<AcademicResource>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ResourceRepository(prefs, ref);
    });
