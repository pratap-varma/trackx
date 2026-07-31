import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/subjects/domain/personal_course_model.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';

class CourseRepository extends StateNotifier<List<PersonalCourse>> {
  static const String _keyCourses = 'px_personal_courses_list';
  final SharedPreferences _prefs;

  CourseRepository(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_keyCourses);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded
            .map((item) => PersonalCourse.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final jsonStr = jsonEncode(state.map((c) => c.toMap()).toList());
    await _prefs.setString(_keyCourses, jsonStr);
  }

  Future<void> createCourse({
    required String title,
    String? courseCode,
    String? description,
    double? credits,
    required String subjectType,
    required List<String> prerequisiteCourseIds,
    required List<int> usuallyOfferedSemesters,
    required String expectedDifficulty,
    String? notes,
    required String status,
  }) async {
    final newId = 'crs-${DateTime.now().millisecondsSinceEpoch}';
    final course = PersonalCourse(
      id: newId,
      userId: 'user_1',
      title: title,
      courseCode: courseCode,
      description: description,
      credits: credits,
      subjectType: subjectType,
      prerequisiteCourseIds: prerequisiteCourseIds,
      usuallyOfferedSemesters: usuallyOfferedSemesters,
      expectedDifficulty: expectedDifficulty,
      notes: notes,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [...state, course];
    await _save();
  }

  Future<void> updateCourse(PersonalCourse course) async {
    state = state.map((c) => c.id == course.id ? course.copyWith(updatedAt: DateTime.now()) : c).toList();
    await _save();
  }

  Future<void> deleteCourse(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _save();
  }

  Future<bool> convertToSubject({
    required String courseId,
    required String semesterId,
    required String facultyName,
    required int colorValue,
    required WidgetRef ref,
  }) async {
    final course = state.firstWhere((c) => c.id == courseId);
    
    // Add to subject repository
    final success = await ref.read(subjectRepositoryProvider.notifier).addSubject(
      semesterId,
      course.title,
      facultyName,
      colorValue,
      75.0,
      code: course.courseCode,
      type: course.subjectType,
      credits: course.credits,
      expectedDifficulty: course.expectedDifficulty,
      status: 'Active',
    );

    if (success) {
      // Mark course as 'Active'
      await updateCourse(course.copyWith(status: 'Active'));
    }
    return success;
  }

  Future<void> restore(List<PersonalCourse> list) async {
    state = list;
    await _save();
  }
}

// Providers
final courseRepositoryProvider =
    StateNotifierProvider<CourseRepository, List<PersonalCourse>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CourseRepository(prefs);
});
