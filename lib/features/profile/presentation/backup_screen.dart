import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/semesters/domain/semester_model.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/programmes/data/programme_repository.dart';
import 'package:trackx/features/programmes/domain/programme_model.dart';
import 'package:trackx/features/subjects/data/dependency_repository.dart';
import 'package:trackx/features/subjects/domain/subject_dependency_model.dart';
import 'package:trackx/features/semesters/data/scenario_repository.dart';
import 'package:trackx/features/semesters/domain/semester_scenario_model.dart';
import 'package:trackx/features/subjects/data/course_repository.dart';
import 'package:trackx/features/subjects/domain/personal_course_model.dart';
import 'package:trackx/features/subjects/data/topic_repository.dart';
import 'package:trackx/features/subjects/domain/topic_model.dart';
import 'package:trackx/features/notes/data/resource_repository.dart';
import 'package:trackx/features/notes/domain/models/academic_resource_model.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _restoreController = TextEditingController();

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  void _showRestoreDialog() {
    _restoreController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Restore JSON Backup',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Paste the generated backup JSON string below. This will validate the schema and show a preview before writing.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _restoreController,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintText: '{"app": "TrackX", ...}',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final jsonStr = _restoreController.text.trim();
                          Navigator.pop(context); // Close paste dialog
                          _processBackupText(jsonStr);
                        },
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _processBackupText(String jsonStr) {
    if (jsonStr.isEmpty) {
      _showMsg('Error: Backup text is empty.');
      return;
    }

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (map['app'] != 'TrackX') {
        _showMsg('Error: Invalid backup. Source app must be TrackX.');
        return;
      }

      final version = map['schemaVersion'] ?? 1;

      // Extract lists
      final semestersList = (map['semesters'] as List? ?? []);
      final subjectsList = (map['subjects'] as List? ?? []);
      final attendanceList = (map['attendance'] as List? ?? []);
      final tasksList = (map['tasks'] as List? ?? []);
      
      final programmesList = (map['programmes'] as List? ?? []);
      final dependenciesList = (map['dependencies'] as List? ?? []);
      final scenariosList = (map['scenarios'] as List? ?? []);
      final coursesList = (map['courses'] as List? ?? []);
      final topicsList = (map['topics'] as List? ?? []);
      final resourcesList = (map['resources'] as List? ?? []);
      final examsList = (map['exams'] as List? ?? []);
      final assignmentsList = (map['assignments'] as List? ?? []);
      final notesList = (map['notes'] as List? ?? []);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            content: GlassContainer(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Restore Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Schema Version: $version', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('• Semesters: ${semestersList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    Text('• Subjects: ${subjectsList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    Text('• Attendance Records: ${attendanceList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    Text('• Tasks: ${tasksList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    if (version >= 2) ...[
                      Text('• Programmes: ${programmesList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('• Dependencies: ${dependenciesList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('• Scenarios: ${scenariosList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('• Topics: ${topicsList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('• Resources: ${resourcesList.length}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'WARNING: Restoring will overwrite all current local data. A safety backup of your current state will be created first.',
                      style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _performRestore(
                              semesters: semestersList,
                              subjects: subjectsList,
                              attendance: attendanceList,
                              tasks: tasksList,
                              programmes: programmesList,
                              dependencies: dependenciesList,
                              scenarios: scenariosList,
                              courses: coursesList,
                              topics: topicsList,
                              resources: resourcesList,
                              exams: examsList,
                              assignments: assignmentsList,
                              notes: notesList,
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                          child: const Text('Confirm Restore'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (_) {
      _showMsg('Error: Invalid JSON format. Unable to parse backup.');
    }
  }

  Future<void> _performRestore({
    required List semesters,
    required List subjects,
    required List attendance,
    required List tasks,
    required List programmes,
    required List dependencies,
    required List scenarios,
    required List courses,
    required List topics,
    required List resources,
    required List exams,
    required List assignments,
    required List notes,
  }) async {
    try {
      // 1. Create a safety backup
      final prefs = ref.read(sharedPreferencesProvider);
      final currentSemesters = ref.read(semesterRepositoryProvider);
      final currentSubjects = ref.read(subjectRepositoryProvider);
      final currentAttendance = ref.read(attendanceRepositoryProvider);
      final currentTasks = ref.read(tasksProvider);
      final currentProgrammes = ref.read(programmeRepositoryProvider);
      final currentDeps = ref.read(dependencyRepositoryProvider);
      final currentScenarios = ref.read(scenarioRepositoryProvider);
      final currentCourses = ref.read(courseRepositoryProvider);
      final currentTopics = ref.read(topicRepositoryProvider);
      final currentResources = ref.read(resourceRepositoryProvider);
      final currentExams = ref.read(examsProvider);
      final currentAssignments = ref.read(assignmentsProvider);
      final currentNotes = ref.read(notesProvider);

      final safetyMap = {
        'app': 'TrackX',
        'schemaVersion': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'semesters': currentSemesters.map((e) => e.toMap()).toList(),
        'subjects': currentSubjects.map((e) => e.toMap()).toList(),
        'attendance': currentAttendance.map((e) => e.toMap()).toList(),
        'tasks': currentTasks.map((e) => e.toMap()).toList(),
        'programmes': currentProgrammes.map((e) => e.toMap()).toList(),
        'dependencies': currentDeps.map((e) => e.toMap()).toList(),
        'scenarios': currentScenarios.map((e) => e.toMap()).toList(),
        'courses': currentCourses.map((e) => e.toMap()).toList(),
        'topics': currentTopics.map((e) => e.toMap()).toList(),
        'resources': currentResources.map((e) => e.toMap()).toList(),
        'exams': currentExams.map((e) => e.toMap()).toList(),
        'assignments': currentAssignments.map((e) => e.toMap()).toList(),
        'notes': currentNotes.map((e) => e.toMap()).toList(),
      };

      await prefs.setString('px_safety_backup', jsonEncode(safetyMap));

      // 2. Perform overrides
      await ref.read(semesterRepositoryProvider.notifier).restore(
            semesters.map((e) => Semester.fromMap(Map<String, dynamic>.from(e))).toList(),
          );
      await ref.read(subjectRepositoryProvider.notifier).restore(
            subjects.map((e) => Subject.fromMap(Map<String, dynamic>.from(e))).toList(),
          );
      // attendance
      final restoredAtt = attendance.map((e) => AttendanceRecord.fromMap(Map<String, dynamic>.from(e))).toList();
      await ref.read(attendanceRepositoryProvider.notifier).restore(restoredAtt);
      
      // tasks
      final restoredTasks = tasks.map((e) => Task.fromMap(Map<String, dynamic>.from(e))).toList();
      ref.read(tasksProvider.notifier).restore(restoredTasks);

      // programmes
      await ref.read(programmeRepositoryProvider.notifier).restore(
            programmes.map((e) => Programme.fromMap(Map<String, dynamic>.from(e))).toList(),
          );
      // dependencies
      await ref.read(dependencyRepositoryProvider.notifier).restore(
            dependencies.map((e) => SubjectDependency.fromMap(Map<String, dynamic>.from(e))).toList(),
          );
      // scenarios
      await ref.read(scenarioRepositoryProvider.notifier).restore(
            scenarios.map((e) => SemesterScenario.fromMap(Map<String, dynamic>.from(e))).toList(),
          );
      // courses
      await ref.read(courseRepositoryProvider.notifier).restore(
            courses.map((e) => PersonalCourse.fromMap(Map<String, dynamic>.from(e))).toList(),
          );
      // topics
      await ref.read(topicRepositoryProvider.notifier).restore(
            topics.map((e) => Topic.fromMap(Map<String, dynamic>.from(e))).toList(),
          );
      // resources
      await ref.read(resourceRepositoryProvider.notifier).restore(
            resources.map((e) => AcademicResource.fromMap(Map<String, dynamic>.from(e))).toList(),
          );
      
      // exams, assignments, notes
      final restoredExams = exams.map((e) => Exam.fromMap(Map<String, dynamic>.from(e))).toList();
      ref.read(examsProvider.notifier).restore(restoredExams);

      final restoredAssignments = assignments.map((e) => Assignment.fromMap(Map<String, dynamic>.from(e))).toList();
      ref.read(assignmentsProvider.notifier).restore(restoredAssignments);

      final restoredNotes = notes.map((e) => Note.fromMap(Map<String, dynamic>.from(e))).toList();
      ref.read(notesProvider.notifier).restore(restoredNotes);

      _showMsg('Success: Backup restored successfully. Safety backup saved.');
    } catch (e) {
      _showMsg('Error performing restore: $e');
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Backup & Export',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Export Card
            const Text(
              'Manual JSON Backups',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create local state backup containing all subjects, semester targets, and daily class records.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GlassPrimaryButton(
                          text: 'Create Backup',
                          onPressed: () {
                            final semesters = ref.read(semesterRepositoryProvider);
                            final subjects = ref.read(subjectRepositoryProvider);
                            final attendance = ref.read(attendanceRepositoryProvider);
                            final tasks = ref.read(tasksProvider);
                            final programmes = ref.read(programmeRepositoryProvider);
                            final dependencies = ref.read(dependencyRepositoryProvider);
                            final scenarios = ref.read(scenarioRepositoryProvider);
                            final courses = ref.read(courseRepositoryProvider);
                            final topics = ref.read(topicRepositoryProvider);
                            final resources = ref.read(resourceRepositoryProvider);
                            final exams = ref.read(examsProvider);
                            final assignments = ref.read(assignmentsProvider);
                            final notes = ref.read(notesProvider);

                            final backupMap = {
                              'app': 'TrackX',
                              'schemaVersion': 2,
                              'exportedAt': DateTime.now().toIso8601String(),
                              'semesters': semesters.map((e) => e.toMap()).toList(),
                              'subjects': subjects.map((e) => e.toMap()).toList(),
                              'attendance': attendance.map((e) => e.toMap()).toList(),
                              'tasks': tasks.map((e) => e.toMap()).toList(),
                              'programmes': programmes.map((e) => e.toMap()).toList(),
                              'dependencies': dependencies.map((e) => e.toMap()).toList(),
                              'scenarios': scenarios.map((e) => e.toMap()).toList(),
                              'courses': courses.map((e) => e.toMap()).toList(),
                              'topics': topics.map((e) => e.toMap()).toList(),
                              'resources': resources.map((e) => e.toMap()).toList(),
                              'exams': exams.map((e) => e.toMap()).toList(),
                              'assignments': assignments.map((e) => e.toMap()).toList(),
                              'notes': notes.map((e) => e.toMap()).toList(),
                            };

                            final backupStr = jsonEncode(backupMap);

                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Colors.transparent,
                                  content: GlassContainer(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Backup Generated (Schema v2)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SelectableText(
                                            backupStr,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white60,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Done'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassPrimaryButton(
                          text: 'Restore Backup',
                          onPressed: _showRestoreDialog,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CSV Export Card
            const Text(
              'CSV Attendance Exports',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export the active semester\'s attendance logs into spreadsheet-ready CSV tables.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  GlassPrimaryButton(
                    text: 'Export CSV',
                    onPressed: () {
                      final subjects = ref.read(subjectRepositoryProvider);
                      final attendance = ref.read(attendanceRepositoryProvider);

                      final csvBuffer = StringBuffer();
                      csvBuffer.writeln('Subject Name,Date,Status,Period');

                      for (final record in attendance) {
                        final subName =
                            subjects
                                .where((s) => s.id == record.subjectId)
                                .firstOrNull
                                ?.name ??
                            'Unknown';
                        csvBuffer.writeln(
                          '"$subName",${record.date.toIso8601String()},${record.status},${record.periodNumber}',
                        );
                      }

                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.transparent,
                            content: GlassContainer(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'CSV Export Complete!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SelectableText(
                                      csvBuffer.toString(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
