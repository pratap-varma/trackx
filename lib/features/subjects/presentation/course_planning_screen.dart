import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/subjects/data/course_repository.dart';
import 'package:trackx/features/subjects/domain/personal_course_model.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class CoursePlanningScreen extends ConsumerStatefulWidget {
  const CoursePlanningScreen({super.key});

  @override
  ConsumerState<CoursePlanningScreen> createState() =>
      _CoursePlanningScreenState();
}

class _CoursePlanningScreenState extends ConsumerState<CoursePlanningScreen> {
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  final _creditsController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedType = 'Theory';
  String _selectedDifficulty = 'Moderate';
  String _selectedStatus = 'Planned'; // 'Interested', 'Planned', etc.
  String _searchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _creditsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCourseDialog() {
    _titleController.clear();
    _codeController.clear();
    _descController.clear();
    _creditsController.clear();
    _selectedType = 'Theory';
    _selectedDifficulty = 'Moderate';
    _selectedStatus = 'Interested';

    showDialog(
      context: context,
      builder: (context) {
        final dropdownBg = context.isDark ? const Color(0xFF131A2B) : Colors.white;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Course Entry',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _titleController,
                    labelText: 'Course Title',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _codeController,
                    labelText: 'Course Code',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _creditsController,
                    labelText: 'Credits',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _descController,
                    labelText: 'Description',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: dropdownBg,
                    initialValue: _selectedType,
                    style: TextStyle(color: context.textColor),
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
                    ],
                    onChanged: (val) => _selectedType = val ?? 'Theory',
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: dropdownBg,
                    initialValue: _selectedDifficulty,
                    style: TextStyle(color: context.textColor),
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
                      labelText: 'Difficulty',
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
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: context.subtextColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final title = _titleController.text.trim();
                          final code = _codeController.text.trim();
                          final credits = double.tryParse(
                            _creditsController.text.trim(),
                          );
                          final desc = _descController.text.trim();

                          if (title.isNotEmpty) {
                            ref
                                .read(courseRepositoryProvider.notifier)
                                .createCourse(
                                  title: title,
                                  courseCode: code.isNotEmpty ? code : null,
                                  description: desc.isNotEmpty ? desc : null,
                                  credits: credits,
                                  subjectType: _selectedType,
                                  prerequisiteCourseIds: [],
                                  usuallyOfferedSemesters: [1, 2],
                                  expectedDifficulty: _selectedDifficulty,
                                  status: _selectedStatus,
                                );
                            Navigator.pop(context);
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

  void _convertCourseToSubject(PersonalCourse course) {
    final semesters = ref
        .read(semesterRepositoryProvider)
        .where((s) => s.status != 'Archived')
        .toList();

    if (semesters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a semester first.')),
      );
      return;
    }

    String selectedSemId = semesters.first.id;

    showDialog(
      context: context,
      builder: (context) {
        final dropdownBg = context.isDark ? const Color(0xFF131A2B) : Colors.white;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return GlassContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Convert to Semester Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      dropdownColor: dropdownBg,
                      initialValue: selectedSemId,
                      style: TextStyle(color: context.textColor),
                      items: semesters
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedSemId = val);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Target Semester',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: context.subtextColor),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final success = await ref
                                .read(courseRepositoryProvider.notifier)
                                .convertToSubject(
                                  courseId: course.id,
                                  semesterId: selectedSemId,
                                  facultyName: 'TBD',
                                  colorValue: 0xFF9C27B0,
                                  ref: ref,
                                );
                            if (context.mounted) Navigator.of(context).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Course mapped to subject successfully.'
                                        : 'Failed. Subject already exists in that semester.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Convert'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(courseRepositoryProvider);
    final filtered = list.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(q) ||
          (c.courseCode?.toLowerCase().contains(q) ?? false);
    }).toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Personal Course Catalog',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor),
          ),
          iconTheme: IconThemeData(color: context.textColor),
          actions: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: context.textColor),
              onPressed: _showAddCourseDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // Safe Notice
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'This is a personal course catalogue. Confirm official availability and requirements with your college.',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    hintText: 'Search catalog by title/code...',
                    hintStyle: TextStyle(color: context.mutedTextColor),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: context.mutedTextColor),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No courses found.',
                        style: TextStyle(color: context.mutedTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final course = filtered[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${course.title} (${course.courseCode ?? "No Code"})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: context.textColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      course.status,
                                      style: const TextStyle(
                                        color: AppTheme.accentPurple,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (course.description != null)
                                  Text(
                                    course.description!,
                                    style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  'Credits: ${course.credits ?? "TBD"} • Type: ${course.subjectType} • Difficulty: ${course.expectedDifficulty}',
                                  style: TextStyle(
                                    color: context.mutedTextColor,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (course.status == 'Interested' ||
                                        course.status == 'Planned')
                                      TextButton.icon(
                                        onPressed: () =>
                                            _convertCourseToSubject(course),
                                        icon: const Icon(Icons.add, size: 14),
                                        label: const Text(
                                          'Convert to Subject',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      onPressed: () => ref
                                          .read(
                                            courseRepositoryProvider.notifier,
                                          )
                                          .deleteCourse(course.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
