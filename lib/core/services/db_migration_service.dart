import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/core/services/hive_db_service.dart';

class DbMigrationService {
  final SharedPreferences _prefs;
  final HiveDbService _hiveDb;

  DbMigrationService(this._prefs, this._hiveDb);

  static const String _keyMigrationCompleted = 'px_migration_completed_v1';

  Future<void> migrate() async {
    // If migration is already marked complete, skip
    if (_prefs.getBool(_keyMigrationCompleted) ?? false) return;

    try {
      // 1. Migrate Semesters
      await _migrateBox('semesters_list', HiveDbService.boxSemesters);

      // 2. Migrate Subjects
      await _migrateBox('subjects_list', HiveDbService.boxSubjects);

      // 3. Migrate Attendance Records
      await _migrateBox('attendance_records_list', HiveDbService.boxAttendance);

      // 4. Migrate Timetable
      await _migrateBox('timetable_entries_list', HiveDbService.boxTimetable);

      // 5. Migrate Tasks
      await _migrateBox('px_tasks_list', HiveDbService.boxTasks);

      // 6. Migrate Assignments
      await _migrateBox('px_assignments_list', HiveDbService.boxAssignments);

      // 7. Migrate Exams
      await _migrateBox('px_exams_list', HiveDbService.boxExams);

      // 8. Migrate Notes
      await _migrateBox('px_notes_list', HiveDbService.boxNotes);

      // 9. Migrate Study Sessions
      await _migrateBox(
        'px_study_sessions_list',
        HiveDbService.boxStudySessions,
      );

      // 10. Migrate Grades
      await _migrateBox('px_course_grades_list', HiveDbService.boxCgpa);

      // 11. Migrate Holidays
      await _migrateBox('px_academic_holidays_list', HiveDbService.boxHolidays);

      // Mark migration complete
      await _prefs.setBool(_keyMigrationCompleted, true);
    } catch (_) {
      // Fail silently to prevent application crashes during start
    }
  }

  Future<void> _migrateBox(String sharedPrefKey, String hiveBoxName) async {
    final raw = _prefs.getString(sharedPrefKey);
    if (raw != null) {
      try {
        final List decoded = jsonDecode(raw);
        final box = _hiveDb.getBox(hiveBoxName);
        for (final item in decoded) {
          if (item is Map) {
            final id = item['id'];
            if (id != null) {
              await box.put(id.toString(), Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (_) {}
    }
  }
}
