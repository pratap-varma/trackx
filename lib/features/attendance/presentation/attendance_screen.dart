import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/providers/attendance_mode_provider.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final _subjectNameController = TextEditingController();
  final _facultyController = TextEditingController();
  final _overrideController = TextEditingController();
  int _selectedColor = 0xFFC084FC; // Violet base

  @override
  void dispose() {
    _subjectNameController.dispose();
    _facultyController.dispose();
    _overrideController.dispose();
    super.dispose();
  }

  void _showAddSubjectDialog(String activeSemId) {
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
                    'Add New Subject',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _subjectNameController,
                    labelText: 'Subject Name',
                    hintText: 'e.g. Computer Networks',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _facultyController,
                    labelText: 'Faculty Name',
                    hintText: 'e.g. Dr. Verma',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _overrideController,
                    labelText: 'Override Target Target (%)',
                    keyboardType: TextInputType.number,
                    hintText: 'Optional',
                  ),
                  const SizedBox(height: 20),
                  // Color selection row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [0xFFC084FC, 0xFF60A5FA, 0xFF34D399, 0xFFF472B6]
                        .map((c) {
                          final isSelected = _selectedColor == c;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = c),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(c),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final name = _subjectNameController.text.trim();
                          final faculty = _facultyController.text.trim();
                          final overrideVal = double.tryParse(
                            _overrideController.text.trim(),
                          );

                          if (name.isNotEmpty) {
                            final success = await ref
                                .read(subjectRepositoryProvider.notifier)
                                .addSubject(
                                  activeSemId,
                                  name,
                                  faculty,
                                  _selectedColor,
                                  overrideVal,
                                );

                            if (success) {
                              _subjectNameController.clear();
                              _facultyController.clear();
                              _overrideController.clear();
                              if (context.mounted) Navigator.pop(context);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Subject with this name already exists.',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Text('Add'),
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

  void _mark(
    String activeSemId,
    String subjectId,
    String status,
    int? period,
  ) async {
    HapticFeedback.mediumImpact();
    final authState = ref.read(authRepositoryProvider);
    final userId = authState.userProfile?.id ?? 'guest';

    final error = await ref
        .read(attendanceRepositoryProvider.notifier)
        .markAttendance(
          userId: userId,
          semesterId: activeSemId,
          subjectId: subjectId,
          date: DateTime.now(),
          periodNumber: period,
          status: status,
        );

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = ref.watch(activeSemesterProvider);
    final mode = ref.watch(attendanceModeProvider);
    final stats = ref.watch(statsProvider);

    if (activeSem == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GlassContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No Active Semester',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create an active semester from Settings to start tracking attendance.',
                  style: TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GlassPrimaryButton(
                  text: 'Manage Semesters',
                  onPressed: () => context.push('/semester-manage'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: 60,
          left: 24,
          right: 24,
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active: ${activeSem.name}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Daily Log',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _showAddSubjectDialog(activeSem.id),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mode Selector switch
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(attendanceModeProvider.notifier)
                          .setMode('subject'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: mode == 'subject'
                              ? Colors.white10
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Subject-wise',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(attendanceModeProvider.notifier)
                          .setMode('period'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: mode == 'period'
                              ? Colors.white10
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Period-wise',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily log view body
            if (stats.allSubjectStats.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Column(
                    children: [
                      const Text(
                        'No Subjects added yet.',
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddSubjectDialog(activeSem.id),
                        child: const Text('Add Subject'),
                      ),
                    ],
                  ),
                ),
              )
            else if (mode == 'subject')
              // Subject-wise log list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.allSubjectStats.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = stats.allSubjectStats[index];
                  final sub = item.subject;

                  return GestureDetector(
                    onTap: () => context.push('/subject-detail/${sub.id}'),
                    child: GlassContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Instructor: ${sub.facultyName}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.greenAccent,
                                ),
                                onPressed: () => _mark(
                                  activeSem.id,
                                  sub.id,
                                  'present',
                                  null,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    _mark(activeSem.id, sub.id, 'absent', null),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              // Period-wise list (Periods 1 to 6 slots)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final period = index + 1;
                  // Allow student to log for a chosen subject for this period
                  return GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period $period',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          dropdownColor: AppTheme.darkBgBase,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Select Subject',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          items: stats.allSubjectStats.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.subject.id,
                              child: Text(item.subject.name),
                            );
                          }).toList(),
                          onChanged: (subId) {
                            if (subId != null) {
                              // Auto trigger a quick present prompt
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.transparent,
                                    content: GlassContainer(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Log Period Attendance',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  _mark(
                                                    activeSem.id,
                                                    subId,
                                                    'present',
                                                    period,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                child: const Text(
                                                  'Present',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  _mark(
                                                    activeSem.id,
                                                    subId,
                                                    'absent',
                                                    period,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text(
                                                  'Absent',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
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
