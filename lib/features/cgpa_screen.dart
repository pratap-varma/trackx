import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class CgpaScreen extends ConsumerStatefulWidget {
  const CgpaScreen({super.key});

  @override
  ConsumerState<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends ConsumerState<CgpaScreen> {
  final _subjectController = TextEditingController();
  final _creditsController = TextEditingController();
  double _gradePoints = 10.0;
  String _gradeLetter = 'O';

  // What-If Simulator fields
  double _simulatedFutureCredits = 15.0;
  double _simulatedFutureGpa = 9.0;

  @override
  void dispose() {
    _subjectController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  void _showAddCourseSheet(String activeSemId) {
    _subjectController.clear();
    _creditsController.clear();
    _gradePoints = 10.0;
    _gradeLetter = 'O';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassContainer(
            borderRadius: 32.0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record Completed Subject',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _subjectController,
                    labelText: 'Subject Name',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _creditsController,
                    labelText: 'Subject Credits (e.g. 4)',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gradeLetter,
                    dropdownColor: AppTheme.darkBgBase,
                    decoration: const InputDecoration(labelText: 'Grade Point'),
                    items:
                        {
                              'O': 10.0,
                              'A+': 9.0,
                              'A': 8.0,
                              'B+': 7.0,
                              'B': 6.0,
                              'C': 5.0,
                              'F': 0.0,
                            }.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text('${e.key} (${e.value.toInt()})'),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _gradeLetter = val;
                          _gradePoints = {
                            'O': 10.0,
                            'A+': 9.0,
                            'A': 8.0,
                            'B+': 7.0,
                            'B': 6.0,
                            'C': 5.0,
                            'F': 0.0,
                          }[val]!;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  GlassPrimaryButton(
                    text: 'Save Course',
                    onPressed: () {
                      final credits =
                          int.tryParse(_creditsController.text.trim()) ?? 0;
                      if (_subjectController.text.trim().isEmpty ||
                          credits <= 0)
                        return;

                      final grade = CourseGrade(
                        id: 'grade-${DateTime.now().millisecondsSinceEpoch}',
                        semesterId: activeSemId,
                        subjectName: _subjectController.text.trim(),
                        credits: credits,
                        grade: _gradeLetter,
                        gradePoints: _gradePoints,
                      );

                      ref.read(courseGradesProvider.notifier).addGrade(grade);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = ref.watch(activeSemesterProvider);
    final grades = ref.watch(courseGradesProvider);
    final gpaSummary = ref.watch(cgpaCalculatorProvider);

    if (activeSem == null) {
      return AppBackground(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              'Please activate a semester in Profile settings first.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ),
      );
    }

    final activeGrades = grades
        .where((g) => g.semesterId == activeSem.id)
        .toList();

    // Math for What-If CGPA Simulation
    double totalCredits = 0;
    double totalWeightedPoints = 0;
    for (final g in activeGrades) {
      totalCredits += g.credits;
      totalWeightedPoints += g.gradePoints * g.credits;
    }

    final simulatedCgpa = (totalCredits + _simulatedFutureCredits) == 0
        ? 0.0
        : (totalWeightedPoints +
                  (_simulatedFutureGpa * _simulatedFutureCredits)) /
              (totalCredits + _simulatedFutureCredits);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'CGPA Tracker',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddCourseSheet(activeSem.id),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Hero GPA display
            GlassContainer(
              child: Column(
                children: [
                  const Text(
                    'CUMULATIVE GPA',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gpaSummary['cgpa']!.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Semester SGPA: ${gpaSummary['sgpa']!.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // What-If Simulator Card
            const Text(
              'What-If CGPA Simulator',
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
                  Text(
                    'Simulated CGPA: ${simulatedCgpa.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Future Semester Credits: ${_simulatedFutureCredits.toInt()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Slider(
                    value: _simulatedFutureCredits,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    activeColor: AppTheme.accentPurple,
                    onChanged: (val) =>
                        setState(() => _simulatedFutureCredits = val),
                  ),
                  Text(
                    'Future Expected GPA: ${_simulatedFutureGpa.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Slider(
                    value: _simulatedFutureGpa,
                    min: 0.0,
                    max: 10.0,
                    divisions: 100,
                    activeColor: AppTheme.accentPurple,
                    onChanged: (val) =>
                        setState(() => _simulatedFutureGpa = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subject grades list
            const Text(
              'Recorded Subject Grades',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (activeGrades.isEmpty)
              const GlassContainer(
                child: Center(
                  child: Text(
                    'No grades recorded for this semester yet.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              )
            else
              ...activeGrades.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassContainer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Credits: ${g.credits}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPurple.withOpacity(0.15),
                                border: Border.all(
                                  color: AppTheme.accentPurple.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                g.grade,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              onPressed: () {
                                ref
                                    .read(courseGradesProvider.notifier)
                                    .deleteGrade(g.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
