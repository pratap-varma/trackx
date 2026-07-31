import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _selectedDate = DateTime.now();
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();
  String _taskCategory = 'Assignment';
  String _taskPriority = 'Medium';

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescController.dispose();
    super.dispose();
  }

  void _showAddTaskSheet(String activeSemId) {
    _taskTitleController.clear();
    _taskDescController.clear();
    _taskCategory = 'Assignment';
    _taskPriority = 'Medium';

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
                    'Create Task / Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _taskTitleController,
                    labelText: 'Title',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _taskDescController,
                    labelText: 'Description',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _taskCategory,
                    dropdownColor: AppTheme.darkBgBase,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items:
                        [
                          'Assignment',
                          'Exam',
                          'Study',
                          'Project',
                          'Personal',
                          'Other',
                        ].map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _taskCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _taskPriority,
                    dropdownColor: AppTheme.darkBgBase,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                      return DropdownMenuItem(value: p, child: Text(p));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _taskPriority = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  GlassPrimaryButton(
                    text: 'Save Task',
                    onPressed: () {
                      if (_taskTitleController.text.trim().isEmpty) return;

                      final task = Task(
                        id: 'task-${DateTime.now().millisecondsSinceEpoch}',
                        userId: 'guest',
                        semesterId: activeSemId,
                        title: _taskTitleController.text.trim(),
                        description: _taskDescController.text.trim().isNotEmpty
                            ? _taskDescController.text.trim()
                            : null,
                        category: _taskCategory,
                        priority: _taskPriority,
                        dueDate: _selectedDate,
                        isCompleted: false,
                        recurrenceRule: 'None',
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      );

                      ref.read(tasksProvider.notifier).addTask(task);
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
    final tasks = ref.watch(tasksProvider);
    final exams = ref.watch(examsProvider);

    if (activeSem == null) {
      return AppBackground(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              'Please active a semester to load planner events.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ),
      );
    }

    final todayTasks = tasks
        .where(
          (t) =>
              t.semesterId == activeSem.id &&
              t.dueDate.year == _selectedDate.year &&
              t.dueDate.month == _selectedDate.month &&
              t.dueDate.day == _selectedDate.day,
        )
        .toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Planner & Calendar',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddTaskSheet(activeSem.id),
            ),
          ],
        ),
        body: Column(
          children: [
            // Calendar Row (7-day strip)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(14, (index) {
                  final date = DateTime.now().add(Duration(days: index - 3));
                  final isSelected =
                      date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentPurple.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentPurple
                              : Colors.white12,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('E').format(date),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Tasks List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                children: [
                  const Text(
                    'Tasks & Deadlines',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (todayTasks.isEmpty)
                    const GlassContainer(
                      child: Center(
                        child: Text(
                          'No tasks scheduled for this day.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    )
                  else
                    ...todayTasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassContainer(
                          child: Row(
                            children: [
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (val) {
                                  ref
                                      .read(tasksProvider.notifier)
                                      .toggleTask(task.id);
                                },
                                activeColor: AppTheme.accentPurple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    if (task.description != null)
                                      Text(
                                        task.description!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white60,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  task.priority,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Upcoming Exams Countdowns
                  const Text(
                    'Upcoming Exams',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (exams.isEmpty)
                    const GlassContainer(
                      child: Center(
                        child: Text(
                          'No exams tracked.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    )
                  else
                    ...exams.map((ex) {
                      final daysLeft = ex.examDate
                          .difference(DateTime.now())
                          .inDays;
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
                                    ex.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${ex.examType} • Progress: ${ex.preparationProgress.toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                daysLeft < 0 ? 'Passed' : '$daysLeft days left',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: daysLeft <= 2
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
