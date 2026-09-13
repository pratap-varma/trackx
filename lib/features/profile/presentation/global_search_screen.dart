import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/notes/data/resource_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class SearchResult {
  final String title;
  final String
  category; // 'Semester', 'Subject', 'Attendance', 'Task', 'Exam', 'Assignment', 'Note', 'Resource'
  final String matchedIn;
  final String? route;

  SearchResult({
    required this.title,
    required this.category,
    required this.matchedIn,
    this.route,
  });
}

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter =
      'All'; // 'All', 'Semester', 'Subject', 'Attendance', 'Task', 'Exam', 'Assignment', 'Note', 'Resource'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SearchResult> _performSearch() {
    if (_query.trim().isEmpty) return [];

    final q = _query.toLowerCase().trim();
    final results = <SearchResult>[];

    // 1. Semesters
    final semesters = ref.read(semesterRepositoryProvider);
    for (final sem in semesters) {
      if (sem.name.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: sem.name,
            category: 'Semester',
            matchedIn: 'Found in Semester name',
            route: '/semester-manage',
          ),
        );
      } else if (sem.notes.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: sem.name,
            category: 'Semester',
            matchedIn: 'Found in Semester notes: "${sem.notes}"',
            route: '/semester-manage',
          ),
        );
      }
    }

    // 2. Subjects
    final subjects = ref.read(subjectRepositoryProvider);
    for (final sub in subjects) {
      if (sub.name.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: sub.name,
            category: 'Subject',
            matchedIn: 'Found in Subject name',
            route: '/subject-detail/${sub.id}',
          ),
        );
      } else if (sub.code?.toLowerCase().contains(q) ?? false) {
        results.add(
          SearchResult(
            title: sub.name,
            category: 'Subject',
            matchedIn: 'Found in Subject code: ${sub.code}',
            route: '/subject-detail/${sub.id}',
          ),
        );
      } else if (sub.facultyName.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: sub.name,
            category: 'Subject',
            matchedIn: 'Found in Faculty name: ${sub.facultyName}',
            route: '/subject-detail/${sub.id}',
          ),
        );
      }
    }

    // 3. Attendance search removed because AttendanceRecord does not store search notes.

    // 4. Tasks
    final tasks = ref.read(tasksProvider);
    for (final task in tasks) {
      if (task.title.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: task.title,
            category: 'Task',
            matchedIn: 'Found in Task title',
          ),
        );
      } else if (task.description?.toLowerCase().contains(q) ?? false) {
        results.add(
          SearchResult(
            title: task.title,
            category: 'Task',
            matchedIn: 'Found in Task details: "${task.description}"',
          ),
        );
      }
    }

    // 5. Exams
    final exams = ref.read(examsProvider);
    for (final exam in exams) {
      if (exam.title.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: exam.title,
            category: 'Exam',
            matchedIn: 'Found in Exam title',
            route: '/exam-prep',
          ),
        );
      } else if (exam.syllabus.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: exam.title,
            category: 'Exam',
            matchedIn: 'Found in Exam syllabus: "${exam.syllabus}"',
            route: '/exam-prep',
          ),
        );
      }
    }

    // 6. Assignments
    final assignments = ref.read(assignmentsProvider);
    for (final assign in assignments) {
      if (assign.title.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: assign.title,
            category: 'Assignment',
            matchedIn: 'Found in Assignment title',
          ),
        );
      } else if (assign.description?.toLowerCase().contains(q) ?? false) {
        results.add(
          SearchResult(
            title: assign.title,
            category: 'Assignment',
            matchedIn:
                'Found in Assignment description: "${assign.description}"',
          ),
        );
      }
    }

    // 7. Notes
    final notes = ref.read(notesProvider);
    for (final note in notes) {
      if (note.title.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: note.title,
            category: 'Note',
            matchedIn: 'Found in Note title',
            route: '/notes',
          ),
        );
      } else if (note.content.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: note.title,
            category: 'Note',
            matchedIn: 'Found in Note content: "${note.content}"',
            route: '/notes',
          ),
        );
      }
    }

    // 8. Resources
    final resources = ref.read(resourceRepositoryProvider);
    for (final res in resources) {
      if (res.title.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            title: res.title,
            category: 'Resource',
            matchedIn: 'Found in Resource title',
            route: '/resources',
          ),
        );
      } else if (res.description?.toLowerCase().contains(q) ?? false) {
        results.add(
          SearchResult(
            title: res.title,
            category: 'Resource',
            matchedIn: 'Found in Resource description: "${res.description}"',
            route: '/resources',
          ),
        );
      }
    }

    // Filter results if needed
    if (_selectedFilter != 'All') {
      return results.where((r) => r.category == _selectedFilter).toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _performSearch();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final mutedTextColor = context.mutedTextColor;

    final categories = [
      'All',
      'Semester',
      'Subject',
      'Attendance',
      'Task',
      'Exam',
      'Assignment',
      'Note',
      'Resource',
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Global search',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
          ),
        ),
        body: Column(
          children: [
            // Search Text Field
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search semesters, subjects, exams, tasks...',
                    hintStyle: TextStyle(color: mutedTextColor),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: mutedTextColor),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _query = val;
                    });
                  },
                ),
              ),
            ),

            // Horizontal Filter Chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : subtextColor,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      selectedColor: context.accentColor,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? context.accentColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06)),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = cat;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Results List
            Expanded(
              child: _query.trim().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: mutedTextColor,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Type to search across TrackX data offline',
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No matching records found.',
                        style: TextStyle(color: subtextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final res = searchResults[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GestureDetector(
                            onTap: () {
                              if (res.route != null) {
                                context.push(res.route!);
                              }
                            },
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1B243B)
                                          : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconForCategory(res.category),
                                      color: context.accentColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          res.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          res.matchedIn,
                                          style: TextStyle(
                                            color: subtextColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (res.route != null)
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: mutedTextColor,
                                      size: 12,
                                    ),
                                ],
                              ),
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

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Semester':
        return Icons.calendar_today_rounded;
      case 'Subject':
        return Icons.school_rounded;
      case 'Attendance':
        return Icons.check_circle_outline_rounded;
      case 'Task':
        return Icons.task_alt_rounded;
      case 'Exam':
        return Icons.assignment_turned_in_rounded;
      case 'Assignment':
        return Icons.assignment_rounded;
      case 'Note':
        return Icons.notes_rounded;
      case 'Resource':
        return Icons.bookmark_rounded;
      default:
        return Icons.search_rounded;
    }
  }
}
