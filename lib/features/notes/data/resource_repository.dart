import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/notes/domain/models/academic_resource_model.dart';

class ResourceRepository extends StateNotifier<List<AcademicResource>> {
  static const String _keyResources = 'px_academic_resources_list';
  final SharedPreferences _prefs;

  ResourceRepository(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_keyResources);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => AcademicResource.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(state.map((r) => r.toMap()).toList());
    await _prefs.setString(_keyResources, jsonStr);
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
    final newId = 'res-${DateTime.now().millisecondsSinceEpoch}';
    final resource = AcademicResource(
      id: newId,
      userId: 'user_1',
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
    state = state.map((r) => r.id == resource.id ? resource.copyWith(updatedAt: DateTime.now()) : r).toList();
    await _save();
  }

  Future<void> toggleFavorite(String id) async {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(
          isFavorite: !r.isFavorite,
          updatedAt: DateTime.now(),
        );
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
  return ResourceRepository(prefs);
});
