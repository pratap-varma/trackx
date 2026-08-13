import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedPriority = 'All';
  bool _isSearching = false;
  final _searchController = TextEditingController();

  // Task form controllers
  final _taskNameController = TextEditingController();
  String? _modalSubjectId;
  String _modalPriority = 'Medium';
  DateTime _modalDueDate = DateTime.now().add(const Duration(days: 2));

  // Exam form controllers
  final _examTitleController = TextEditingController();
  final _examSyllabusController = TextEditingController();
  String _examType = 'Midterm';
  DateTime _examDate = DateTime.now().add(const Duration(days: 5));
  TimeOfDay _examTime = const TimeOfDay(hour: 10, minute: 30);

  @override
  void dispose() {
    _searchController.dispose();
    _taskNameController.dispose();
    _examTitleController.dispose();
    _examSyllabusController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddDialog() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0E1628),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Planner Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tabs: Task vs Exam
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: const Color(0xFF5B5FEF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: '📝 Task / Assignment'),
                      Tab(text: '🎓 Exam / Quiz'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 380,
                  child: TabBarView(
                    children: [
                      _buildTaskForm(ctx),
                      _buildExamForm(ctx),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskForm(BuildContext ctx) {
    final subjects = ref.watch(subjectRepositoryProvider);
    return StatefulBuilder(
      builder: (context, setTaskState) {
        if (_modalSubjectId == null && subjects.isNotEmpty) {
          _modalSubjectId = subjects.first.id;
        }

        return ListView(
          shrinkWrap: true,
          children: [
            GlassTextField(
              controller: _taskNameController,
              labelText: 'Task / Assignment Title',
              hintText: 'e.g. Cognitive Psychology Paper',
            ),
            const SizedBox(height: 14),

            // Subject selector
            const Text('Subject', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF131A2B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: const Color(0xFF0E1628),
                  value: _modalSubjectId,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: subjects.map((s) {
                    return DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setTaskState(() => _modalSubjectId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Due Date
            const Text('Due Date', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: _modalDueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setTaskState(() => _modalDueDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MM/dd/yyyy').format(_modalDueDate),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Priority
            const Text('Priority Level', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: ['Low', 'Medium', 'High'].map((p) {
                final isSelected = _modalPriority == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setTaskState(() => _modalPriority = p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF5B5FEF) : const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Center(
                        child: Text(
                          p,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Add button
            GestureDetector(
              onTap: () {
                final title = _taskNameController.text.trim();
                if (title.isNotEmpty) {
                  final activeSem = ref.read(activeSemesterProvider);
                  final newTask = Task(
                    id: 'task-${DateTime.now().millisecondsSinceEpoch}',
                    userId: 'user',
                    semesterId: activeSem?.id ?? 'sem-1',
                    subjectId: _modalSubjectId,
                    title: title,
                    category: 'Assignment',
                    priority: _modalPriority,
                    dueDate: _modalDueDate,
                    isCompleted: false,
                    recurrenceRule: 'None',
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );

                  ref.read(tasksProvider.notifier).addTask(newTask);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "$title" to Planner!')),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5FEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('Save Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExamForm(BuildContext ctx) {
    final subjects = ref.watch(subjectRepositoryProvider);
    return StatefulBuilder(
      builder: (context, setExamState) {
        if (_modalSubjectId == null && subjects.isNotEmpty) {
          _modalSubjectId = subjects.first.id;
        }

        return ListView(
          shrinkWrap: true,
          children: [
            GlassTextField(
              controller: _examTitleController,
              labelText: 'Exam / Quiz Title',
              hintText: 'e.g. Chemistry Midterm Exam',
            ),
            const SizedBox(height: 14),

            // Subject selector
            const Text('Subject', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF131A2B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: const Color(0xFF0E1628),
                  value: _modalSubjectId,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: subjects.map((s) {
                    return DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setExamState(() => _modalSubjectId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Exam Date & Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Exam Date', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: _examDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setExamState(() => _examDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A2B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(_examDate),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: _examTime,
                          );
                          if (picked != null) {
                            setExamState(() => _examTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A2B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            _examTime.format(context),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Exam Type (Midterm, Final, Quiz)
            const Text('Exam Type', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: ['Quiz', 'Midterm', 'Final'].map((t) {
                final isSelected = _examType == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setExamState(() => _examType = t),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF5B5FEF) : const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Center(
                        child: Text(
                          t,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Add Exam button
            GestureDetector(
              onTap: () {
                final title = _examTitleController.text.trim();
                if (title.isNotEmpty) {
                  final activeSem = ref.read(activeSemesterProvider);
                  final newExam = Exam(
                    id: 'exam-${DateTime.now().millisecondsSinceEpoch}',
                    userId: 'user',
                    semesterId: activeSem?.id ?? 'sem-1',
                    subjectId: _modalSubjectId ?? 'sub-1',
                    title: title,
                    examType: _examType,
                    examDate: _examDate,
                    startTime: _examTime.format(context),
                    syllabus: 'Chapters 1-5',
                    preparationProgress: 10.0,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );

                  ref.read(examsProvider.notifier).addExam(newExam);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Scheduled "$title" in Exams!')),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5FEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('Save Upcoming Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAllExamsSheet(List<Exam> exams) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Exams & Quizzes',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: Color(0xFFC0C1FF)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (exams.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text('No upcoming exams scheduled.', style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              ...exams.map((ex) {
                final daysLeft = ex.examDate.difference(DateTime.now()).inDays;
                final badge = daysLeft <= 0
                    ? 'TODAY'
                    : daysLeft == 1
                        ? 'TOMORROW'
                        : 'IN $daysLeft DAYS';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            badge,
                            style: const TextStyle(color: Color(0xFFFF8B94), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          Text(
                            '${(ex.preparationProgress).toInt()}% Prep',
                            style: const TextStyle(color: Color(0xFFC0C1FF), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ex.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(ex.examDate)} • ${ex.startTime}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B243B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFC0C1FF), size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Planner Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Smart study & exam reminders', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _reminderItem('Chemistry Midterm in 3 days', 'Review lab notes before 8 PM tonight', Icons.science_outlined),
            const SizedBox(height: 12),
            _reminderItem('Calculus Assignment Due Tomorrow', 'Submission portal closes at 11:59 PM', Icons.calculate_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Mark All as Read', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _reminderItem(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7BD0FF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final exams = ref.watch(examsProvider);
    final subjects = ref.watch(subjectRepositoryProvider);

    // Week Strip
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final monthYearFormatted = DateFormat('MMMM yyyy').format(_selectedDate);

    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredTasks = tasks.where((t) {
      final matchesPriority = _selectedPriority == 'All' || t.priority.toLowerCase() == _selectedPriority.toLowerCase();
      final matchesSearch = searchQuery.isEmpty || t.title.toLowerCase().contains(searchQuery);
      return matchesPriority && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.calendar_today_rounded, color: Colors.white, size: 22),
        ),
        titleSpacing: 8,
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5B5FEF).withValues(alpha: 0.5)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search tasks & exams...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              )
            : const Text(
                'Planner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: Colors.white, size: 22),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
            onPressed: _showNotificationsSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
            children: [
              // Month Header + Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthYearFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)));
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)));
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Selector Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDays.map((day) {
                  final isSelected = _isSameDay(day, _selectedDate);
                  final dayName = DateFormat('E').format(day).toUpperCase();
                  final dayNumber = day.day.toString();

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = day),
                    child: Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFC0C1FF) : const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF0E00AA) : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayNumber,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF0E00AA) : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Upcoming Exams Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Exams',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAllExamsSheet(exams),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF7BD0FF),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Horizontal Exam Cards
              if (exams.isEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _examCard(
                        badge: 'IN 3 DAYS',
                        title: 'Chemistry Midterm',
                        date: 'Oct 28 • 10:30 AM',
                        icon: Icons.science_outlined,
                        progress: 0.7,
                        onTap: () => _showAllExamsSheet(exams),
                      ),
                      const SizedBox(width: 14),
                      _examCard(
                        badge: 'IN 12 DAYS',
                        title: 'Calculus Final',
                        date: 'Nov 06 • 09:00 AM',
                        icon: Icons.calculate_outlined,
                        progress: 0.3,
                        onTap: () => _showAllExamsSheet(exams),
                      ),
                    ],
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: exams.map((ex) {
                      final daysLeft = ex.examDate.difference(DateTime.now()).inDays;
                      final badge = daysLeft <= 0
                          ? 'TODAY'
                          : daysLeft == 1
                              ? 'TOMORROW'
                              : 'IN $daysLeft DAYS';

                      return Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: _examCard(
                          badge: badge,
                          title: ex.title,
                          date: '${DateFormat('MMM dd').format(ex.examDate)} • ${ex.startTime}',
                          icon: Icons.school_outlined,
                          progress: ex.preparationProgress / 100.0,
                          onTap: () => _showAllExamsSheet(exams),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),

              // Assignments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assignments & Tasks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) => setState(() => _selectedPriority = val),
                    color: const Color(0xFF131A2B),
                    itemBuilder: (ctx) => ['All', 'High', 'Medium', 'Low'].map((p) {
                      return PopupMenuItem<String>(
                        value: p,
                        child: Text(p, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B243B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedPriority,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (filteredTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2B),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('No tasks matching your search.', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _showAddDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B5FEF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('+ Add Task / Exam'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredTasks.map((t) {
                  final isDone = t.isCompleted;
                  final subName = subjects.where((s) => s.id == t.subjectId).firstOrNull?.name ?? 'General';
                  final tagColor = switch (t.priority.toLowerCase()) {
                    'high' => const Color(0xFFEF4444),
                    'low' => const Color(0xFF10B981),
                    _ => const Color(0xFF5B5FEF),
                  };

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(tasksProvider.notifier).toggleTask(t.id);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? const Color(0xFF10B981) : Colors.transparent,
                              border: Border.all(
                                color: isDone ? Colors.transparent : Colors.white38,
                                width: 2,
                              ),
                            ),
                            child: isDone
                                ? const Icon(Icons.check_rounded, color: Colors.black, size: 18)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: TextStyle(
                                  color: isDone ? Colors.white38 : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$subName • ${DateFormat('MMM dd').format(t.dueDate)}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDone ? 'DONE' : t.priority.toUpperCase(),
                            style: TextStyle(
                              color: tagColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Daily Schedule Timeline
              const Text(
                'Daily Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _scheduleTimelineItem(
                time: '09:00 - 10:30 AM',
                title: 'Theoretical Physics',
                subtitle: 'Room 402 • Prof. Higgins',
              ),
              const SizedBox(height: 14),

              _scheduleTimelineItem(
                time: '11:00 - 12:30 PM',
                title: 'English Literature',
                subtitle: 'Hall B • Dr. Aris',
              ),
              const SizedBox(height: 14),

              // Suggested Study Block
              _suggestedStudyBlock(
                title: 'Prep for Chem Midterm',
                subtitle: 'Based on your performance in Lab 2',
                onAdd: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scheduled "Prep for Chem Midterm" into your calendar!')),
                  );
                },
              ),
            ],
          ),

          // Floating Add Button
          Positioned(
            right: 20,
            bottom: 84,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC0C1FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B5FEF).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, color: Color(0xFF0E00AA), size: 28),
                onPressed: _showAddDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _examCard({
    required String badge,
    required String title,
    required String date,
    required IconData icon,
    required double progress,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131A2B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFFFF8B94),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Icon(icon, color: Colors.white30, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFC0C1FF)),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _scheduleTimelineItem({
    required String time,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFC0C1FF),
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _suggestedStudyBlock({
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF7BD0FF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SUGGESTED STUDY BLOCK',
                style: TextStyle(
                  color: Color(0xFF7BD0FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF5B5FEF).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC0C1FF), size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B243B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add to Schedule',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
