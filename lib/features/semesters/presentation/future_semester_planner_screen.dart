import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/programmes/data/programme_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class FutureSemesterPlannerScreen extends ConsumerStatefulWidget {
  const FutureSemesterPlannerScreen({super.key});

  @override
  ConsumerState<FutureSemesterPlannerScreen> createState() =>
      _FutureSemesterPlannerScreenState();
}

class _FutureSemesterPlannerScreenState
    extends ConsumerState<FutureSemesterPlannerScreen> {
  final _semNameController = TextEditingController();
  final _subjNameController = TextEditingController();
  final _subjCodeController = TextEditingController();
  final _creditsController = TextEditingController();
  final _periodsController = TextEditingController();

  String? _selectedSemesterId;
  String _selectedType = 'Theory';
  String _selectedDifficulty = 'Moderate';

  @override
  void dispose() {
    _semNameController.dispose();
    _subjNameController.dispose();
    _subjCodeController.dispose();
    _creditsController.dispose();
    _periodsController.dispose();
    super.dispose();
  }

  void _showAddSemesterDialog() {
    _semNameController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ctx.isDark ? const Color(0xFF0E1628) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: ctx.subtleBorderColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create Upcoming Semester',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ctx.textColor,
                ),
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: _semNameController,
                labelText: 'Semester Name (e.g. Semester 6)',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: ctx.mutedTextColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = _semNameController.text.trim();
                      final activeProg = ref.read(activeProgrammeProvider);
                      if (name.isNotEmpty && activeProg != null) {
                        await ref
                            .read(semesterRepositoryProvider.notifier)
                            .createSemester(
                              name,
                              6, // number
                              DateTime.now().add(
                                const Duration(days: 120),
                              ), // Future start date
                              null,
                              programmeId: activeProg.id,
                              status: 'Upcoming',
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSubjectDialog() {
    if (_selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create an upcoming semester first.'),
        ),
      );
      return;
    }
    _subjNameController.clear();
    _subjCodeController.clear();
    _creditsController.clear();
    _periodsController.clear();
    _selectedType = 'Theory';
    _selectedDifficulty = 'Moderate';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ctx.isDark ? const Color(0xFF0E1628) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: ctx.subtleBorderColor),
          ),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Plan New Subject',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ctx.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _subjNameController,
                    labelText: 'Subject Name',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _subjCodeController,
                    labelText: 'Subject Code',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _creditsController,
                    labelText: 'Credits',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _periodsController,
                    labelText: 'Weekly Periods',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: ctx.isDark ? const Color(0xFF131A2B) : Colors.white,
                    initialValue: _selectedType,
                    style: TextStyle(color: ctx.textColor),
                    items: const [
                      DropdownMenuItem(value: 'Theory', child: Text('Theory')),
                      DropdownMenuItem(
                        value: 'Laboratory',
                        child: Text('Laboratory'),
                      ),
                      DropdownMenuItem(
                        value: 'Project',
                        child: Text('Project'),
                      ),
                      DropdownMenuItem(
                        value: 'Elective',
                        child: Text('Elective'),
                      ),
                      DropdownMenuItem(
                        value: 'Internship',
                        child: Text('Internship'),
                      ),
                      DropdownMenuItem(
                        value: 'Seminar',
                        child: Text('Seminar'),
                      ),
                      DropdownMenuItem(
                        value: 'Workshop',
                        child: Text('Workshop'),
                      ),
                    ],
                    onChanged: (val) => _selectedType = val ?? 'Theory',
                    decoration: InputDecoration(
                      labelText: 'Subject Type',
                      labelStyle: TextStyle(color: ctx.mutedTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: ctx.isDark ? const Color(0xFF131A2B) : Colors.white,
                    initialValue: _selectedDifficulty,
                    style: TextStyle(color: ctx.textColor),
                    items: const [
                      DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                      DropdownMenuItem(
                        value: 'Moderate',
                        child: Text('Moderate'),
                      ),
                      DropdownMenuItem(
                        value: 'Challenging',
                        child: Text('Challenging'),
                      ),
                      DropdownMenuItem(
                        value: 'Very Challenging',
                        child: Text('Very Challenging'),
                      ),
                    ],
                    onChanged: (val) => _selectedDifficulty = val ?? 'Moderate',
                    decoration: InputDecoration(
                      labelText: 'Expected Difficulty',
                      labelStyle: TextStyle(color: ctx.mutedTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: ctx.mutedTextColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final name = _subjNameController.text.trim();
                          final code = _subjCodeController.text.trim();
                          final credits = double.tryParse(
                            _creditsController.text.trim(),
                          );
                          final periods = int.tryParse(
                            _periodsController.text.trim(),
                          );

                          if (name.isNotEmpty && _selectedSemesterId != null) {
                            await ref
                                .read(subjectRepositoryProvider.notifier)
                                .addSubject(
                                  _selectedSemesterId!,
                                  name,
                                  'TBD',
                                  0xFF9C27B0,
                                  75.0,
                                  code: code.isNotEmpty ? code : null,
                                  type: _selectedType,
                                  credits: credits,
                                  weeklyPeriods: periods,
                                  expectedDifficulty: _selectedDifficulty,
                                  status: 'Planned',
                                );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          }
                        },
                        child: const Text('Add Plan'),
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

  @override
  Widget build(BuildContext context) {
    final activeProg = ref.watch(activeProgrammeProvider);
    final semesters = ref
        .watch(semesterRepositoryProvider)
        .where(
          (s) =>
              s.programmeId == (activeProg?.id ?? '') && s.status == 'Upcoming',
        )
        .toList();
    final subjects = ref.watch(subjectRepositoryProvider);

    if (_selectedSemesterId == null && semesters.isNotEmpty) {
      _selectedSemesterId = semesters.first.id;
    }

    final plannedSubjects = subjects
        .where(
          (s) => s.semesterId == _selectedSemesterId && s.status == 'Planned',
        )
        .toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Future Semester Planner',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor),
          ),
          iconTheme: IconThemeData(color: context.textColor),
          actions: [
            IconButton(
              icon: Icon(Icons.add_box_rounded, color: context.textColor),
              onPressed: _showAddSemesterDialog,
            ),
          ],
        ),
        body: activeProg == null
            ? Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Set an active programme in settings to start planning upcoming semesters.',
                    style: TextStyle(color: context.subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    'Plan upcoming semesters and build mock syllabus catalogs offline.',
                    style: TextStyle(color: context.subtextColor, fontSize: 11),
                  ),
                  const SizedBox(height: 20),

                  // Select Semester Dropdown
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          dropdownColor: context.isDark ? const Color(0xFF131A2B) : Colors.white,
                          initialValue: _selectedSemesterId,
                          style: TextStyle(color: context.textColor),
                          decoration: InputDecoration(
                            labelText: 'Select Target Semester',
                            labelStyle: TextStyle(color: context.mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: semesters.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSemesterId = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppTheme.accentPurple,
                          size: 36,
                        ),
                        onPressed: _showAddSubjectDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Planned subjects list
                  Text(
                    'Planned Subjects Checkbox',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  plannedSubjects.isEmpty
                      ? Center(
                          child: Text(
                            'No subjects planned for this semester yet.',
                            style: TextStyle(
                              color: context.mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: plannedSubjects.length,
                          itemBuilder: (context, index) {
                            final sub = plannedSubjects[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${sub.name} (${sub.code ?? "No Code"})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: context.textColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Credits: ${sub.credits ?? "Not Set"} • Type: ${sub.type} • Difficulty: ${sub.expectedDifficulty}',
                                            style: TextStyle(
                                              color: context.subtextColor,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        // Activate Button
                                        IconButton(
                                          icon: Icon(
                                            Icons.play_circle_outline,
                                            color: context.isDark ? Colors.greenAccent : Colors.green.shade700,
                                          ),
                                          tooltip: 'Convert to Active Subject',
                                          onPressed: () {
                                            ref
                                                .read(
                                                  subjectRepositoryProvider
                                                      .notifier,
                                                )
                                                .editSubject(
                                                  sub.id,
                                                  sub.name,
                                                  sub.facultyName,
                                                  sub.colorValue,
                                                  sub.targetAttendance,
                                                  status: 'Active',
                                                );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(
                                                  subjectRepositoryProvider
                                                      .notifier,
                                                )
                                                .deleteSubject(sub.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }
}
