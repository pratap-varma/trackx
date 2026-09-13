import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/calendar/providers/calendar_provider.dart';
import 'package:trackx/features/calendar/presentation/widgets/calendar_event_details_sheet.dart';
import 'package:trackx/features/calendar/presentation/widgets/calendar_integration_sheet.dart';
import 'package:trackx/features/planner/providers/calendar_conflict_provider.dart';
import 'package:trackx/features/planner/presentation/widgets/calendar_conflict_details_sheet.dart';
import 'package:trackx/features/planner/presentation/widgets/exam_import_sheet.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = context.cardColor;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final tabBg = isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Planner Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: subtextColor,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Tabs: Task vs Exam
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tabBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: context.accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: subtextColor,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: '📝 Task / Assignment'),
                      Tab(text: '🎓 Exam / Quiz'),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                SizedBox(
                  height: 480,
                  child: TabBarView(
                    children: [_buildTaskForm(ctx), _buildExamForm(ctx)],
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
            SizedBox(height: 14),

            // Subject selector
            Text('Subject', style: TextStyle(color: context.subtextColor, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: context.cardColor,
                  value: _modalSubjectId,
                  isExpanded: true,
                  style: TextStyle(color: context.textColor, fontSize: 14),
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
            SizedBox(height: 14),

            // Due Date
            Text('Due Date', style: TextStyle(color: context.subtextColor, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MM/dd/yyyy').format(_modalDueDate),
                      style: TextStyle(color: context.textColor, fontSize: 14),
                    ),
                    Icon(
                      Icons.calendar_today_rounded,
                      color: context.subtextColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14),

            // Priority
            Text('Priority Level', style: TextStyle(color: context.subtextColor, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
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
                        color: isSelected
                            ? context.accentColor
                            : (context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (context.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          p,
                          style: TextStyle(
                            color: isSelected ? Colors.white : context.subtextColor,
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
            SizedBox(height: 20),

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
                  _taskNameController.clear();
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
                  color: context.accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Save Assignment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
            SizedBox(height: 14),

            // Subject selector
            Text('Subject', style: TextStyle(color: context.subtextColor, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: context.cardColor,
                  value: _modalSubjectId,
                  isExpanded: true,
                  style: TextStyle(color: context.textColor, fontSize: 14),
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
            SizedBox(height: 14),

            // Exam Date & Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exam Date', style: TextStyle(color: context.subtextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(_examDate),
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time', style: TextStyle(color: context.subtextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            _examTime.format(context),
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),

            // Syllabus input
            GlassTextField(
              controller: _examSyllabusController,
              labelText: 'Syllabus / Key Topics',
              hintText: 'e.g. Chapters 1-5, Formulas & Definitions',
            ),
            SizedBox(height: 14),

            // Exam Type (Midterm, Final, Quiz)
            Text('Exam Type', style: TextStyle(color: context.subtextColor, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
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
                        color: isSelected
                            ? context.accentColor
                            : (context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (context.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          t,
                          style: TextStyle(
                            color: isSelected ? Colors.white : context.subtextColor,
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
            SizedBox(height: 20),

            // Add Exam button
            GestureDetector(
              onTap: () {
                final title = _examTitleController.text.trim();
                final syllabus = _examSyllabusController.text.trim().isNotEmpty
                    ? _examSyllabusController.text.trim()
                    : 'Chapters 1-5';
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
                    syllabus: syllabus,
                    preparationProgress: 10.0,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );

                  ref.read(examsProvider.notifier).addExam(newExam);
                  _examTitleController.clear();
                  _examSyllabusController.clear();
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
                  color: context.accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Save Upcoming Exam',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
        decoration: BoxDecoration(
          color: context.cardColor,
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
                  color: context.isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Exams & Quizzes',
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_rounded, color: context.accentColor),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddDialog();
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            if (exams.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No upcoming exams scheduled.',
                    style: TextStyle(color: context.subtextColor),
                  ),
                ),
              )
            else
              ...exams.map((ex) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final examDay = DateTime(ex.examDate.year, ex.examDate.month, ex.examDate.day);
                final daysLeft = examDay.difference(today).inDays;
                final badge = daysLeft <= 0
                    ? 'TODAY'
                    : daysLeft == 1
                    ? 'TOMORROW'
                    : 'IN $daysLeft DAYS';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: context.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            badge,
                            style: TextStyle(
                              color: Color(0xFFFF8B94),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${(ex.preparationProgress).toInt()}% Prep',
                                style: TextStyle(
                                  color: Color(0xFFC0C1FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showEditScheduledExamDialog(ex);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: context.accentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: context.accentColor,
                                    size: 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  ref.read(examsProvider.notifier).deleteExam(ex.id);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted "${ex.title}"'),
                                      duration: const Duration(milliseconds: 1500),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        ex.title,
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${DateFormat('EEEE, MMM dd, yyyy').format(ex.examDate)} • ${ex.startTime}',
                        style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 12,
                        ),
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

  void _showEditScheduledExamDialog(Exam exam) {
    HapticFeedback.lightImpact();
    DateTime editDate = exam.examDate;
    String editType = exam.examType;
    final titleCtrl = TextEditingController(text: exam.title);
    final timeCtrl = TextEditingController(text: exam.startTime);
    final syllabusCtrl = TextEditingController(text: exam.syllabus);
    double progress = exam.preparationProgress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setEditState) {
          return Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
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
                        color: context.isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Exam Details',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: context.subtextColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // 1. Interactive Date Picker
                  Text(
                    'EXAM DATE',
                    style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: editDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setEditState(() => editDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, color: context.accentColor, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('EEEE, MMM d, yyyy').format(editDate),
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Change Date',
                              style: TextStyle(
                                color: context.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Exam Type Selector
                  Text(
                    'EXAM TYPE',
                    style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Quiz', 'Midterm', 'Final', 'Lab Practical', 'Internal'].map((t) {
                        final isSelected = editType.toLowerCase() == t.toLowerCase();
                        return GestureDetector(
                          onTap: () => setEditState(() => editType = t),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? context.accentColor : (context.isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : (context.isDark ? Colors.white12 : Colors.black12),
                              ),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: isSelected ? Colors.white : context.subtextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 14),

                  // 3. Exam Title
                  GlassTextField(
                    controller: titleCtrl,
                    labelText: 'Exam Title',
                  ),
                  SizedBox(height: 14),

                  // 4. Time & Syllabus
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: timeCtrl,
                          labelText: 'Time (e.g. 10:30 AM)',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: GlassTextField(
                          controller: syllabusCtrl,
                          labelText: 'Syllabus / Topics',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // 5. Preparation Progress Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PREPARATION PROGRESS',
                        style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${progress.toInt()}%',
                        style: TextStyle(
                          color: Color(0xFF7BD0FF),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: progress,
                    min: 0.0,
                    max: 100.0,
                    activeColor: context.accentColor,
                    inactiveColor: context.isDark ? Colors.white12 : Colors.black12,
                    onChanged: (val) => setEditState(() => progress = val),
                  ),
                  const SizedBox(height: 16),

                  // Save Changes Button
                  GestureDetector(
                    onTap: () {
                      final newTitle = titleCtrl.text.trim();
                      if (newTitle.isNotEmpty) {
                        final updated = exam.copyWith(
                          title: newTitle,
                          examDate: editDate,
                          examType: editType,
                          startTime: timeCtrl.text.trim(),
                          syllabus: syllabusCtrl.text.trim(),
                          preparationProgress: progress,
                          updatedAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        ref.read(examsProvider.notifier).editExam(updated);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exam details updated successfully!'),
                            duration: Duration(milliseconds: 1500),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.accentColor, context.tertiaryColor],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationsSheet() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = context.cardColor;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final iconBg = isDark ? const Color(0xFF1B243B) : const Color(0xFFE2E8F0);
    final emptyCardBg = isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFC0C1FF),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planner Notifications',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Smart study & exam reminders',
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Builder(
              builder: (context) {
                final currentExams = ref.read(examsProvider);
                final currentTasks = ref
                    .read(tasksProvider)
                    .where((t) => !t.isCompleted)
                    .toList();

                if (currentExams.isEmpty && currentTasks.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: emptyCardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'No active reminders. Add exams or tasks to get alerts.',
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...currentExams.take(2).map((ex) {
                      final daysLeft = ex.examDate
                          .difference(DateTime.now())
                          .inDays;
                      final daysStr = daysLeft <= 0
                          ? 'today'
                          : (daysLeft == 1 ? 'tomorrow' : 'in $daysLeft days');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _reminderItem(
                          '${ex.title} $daysStr',
                          'Exam scheduled at ${ex.startTime}',
                          Icons.school_outlined,
                          isDark,
                          textColor,
                          subtextColor,
                        ),
                      );
                    }),
                    ...currentTasks.take(2).map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _reminderItem(
                          t.title,
                          'Priority: ${t.priority}',
                          Icons.task_alt_rounded,
                          isDark,
                          textColor,
                          subtextColor,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Mark All as Read',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _reminderItem(String title, String subtitle, IconData icon, bool isDark, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7BD0FF), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: subtextColor, fontSize: 11),
                ),
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
    final timetableEntries = ref.watch(timetableRepositoryProvider);
    final activeSem = ref.watch(activeSemesterProvider);
    final allHolidays = ref.watch(calendarRepositoryProvider);
    final selectedDayHolidays = ref.watch(
      holidaysForSelectedDateProvider(_selectedDate),
    );
    final selectedPersonalEvents = ref.watch(
      personalEventsForSelectedDateProvider(_selectedDate),
    );
    final conflicts = ref.watch(
      conflictsForSelectedDateProvider(_selectedDate),
    );
    final isCalendarConnected = ref.watch(isCalendarConnectedProvider);

    final isSelectedHoliday = ref.watch(isHolidayDateProvider(_selectedDate));
    final overrideDay = ref.watch(dayOfWeekOverrideProvider(_selectedDate));
    final effectiveDay = overrideDay ?? _selectedDate.weekday;

    final dayClasses = isSelectedHoliday
        ? <TimetableEntry>[]
        : timetableEntries
            .where(
              (e) =>
                  e.dayOfWeek == effectiveDay &&
                  (activeSem == null || e.semesterId == activeSem.id) &&
                  e.isEnabled,
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Week Strip
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final monthYearFormatted = DateFormat('MMMM yyyy').format(_selectedDate);

    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredTasks = tasks.where((t) {
      final matchesPriority =
          _selectedPriority == 'All' ||
          t.priority.toLowerCase() == _selectedPriority.toLowerCase();
      final matchesSearch =
          searchQuery.isEmpty || t.title.toLowerCase().contains(searchQuery);
      return matchesPriority && matchesSearch;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final mutedTextColor = context.mutedTextColor;
    final searchBg = isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9);
    final dayPillBg = isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9);

    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(
            Icons.calendar_today_rounded,
            color: textColor,
            size: 22,
          ),
        ),
        titleSpacing: 8,
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: searchBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.accentColor.withValues(alpha: 0.5),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search tasks & exams...',
                    hintStyle: TextStyle(color: mutedTextColor, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              )
            : Text(
                'Planner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            tooltip: isCalendarConnected
                ? 'Google Calendar (Connected)'
                : 'Connect Google Calendar',
            icon: Icon(
              Icons.event_available_rounded,
              color: isCalendarConnected
                  ? const Color(0xFF10B981)
                  : subtextColor,
              size: 22,
            ),
            onPressed: () => CalendarIntegrationSheet.show(context),
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: textColor,
              size: 22,
            ),
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
            icon: Icon(
              Icons.notifications_none_rounded,
              color: textColor,
              size: 22,
            ),
            onPressed: _showNotificationsSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            key: const PageStorageKey('planner_scroll'),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
            children: [
              // Month Header + Navigation (With Swipe to Change Week)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -80) {
                    // Swiped Left -> Move to Next Week (+7 days)
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 7));
                    });
                  } else if (details.primaryVelocity! > 80) {
                    // Swiped Right -> Move to Previous Week (-7 days)
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                    });
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          monthYearFormatted,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                color: subtextColor,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(
                                  () => _selectedDate = _selectedDate.subtract(
                                    const Duration(days: 7),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 16),
                            IconButton(
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                color: subtextColor,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(
                                  () => _selectedDate = _selectedDate.add(
                                    const Duration(days: 7),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Date Selector Strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: weekDays.map((day) {
                        final isSelected = _isSameDay(day, _selectedDate);
                        final dayName = DateFormat('E').format(day).toUpperCase();
                        final dayNumber = day.day.toString();

                        final isHolidayDay = allHolidays.any((h) => h.occursOn(day));
                        final hasConflict = ref.watch(hasConflictOnDateProvider(day));

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = day),
                          child: Container(
                            width: 44,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.accentColor
                                  : dayPillBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : hasConflict
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                    : isHolidayDay
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                    : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : subtextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  dayNumber,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (hasConflict) ...[
                                  SizedBox(height: 4),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ] else if (isHolidayDay) ...[
                                  SizedBox(height: 4),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Upcoming Exams Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Exams',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ExamImportSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: context.accentColor.withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.accentColor.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.document_scanner_rounded,
                                color: context.accentColor,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Scan Date-Sheet',
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      TextButton(
                        onPressed: () => _showAllExamsSheet(exams),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: context.accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Horizontal Exam Cards
              if (exams.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131A2B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B243B) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.event_note_outlined,
                              color: context.accentColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No upcoming exams scheduled',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Upload your exam timetable PDF or photo to automatically generate exam countdowns.',
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ExamImportSheet.show(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      context.accentColor,
                                      context.tertiaryColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.document_scanner_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '📸 Scan Exam PDF',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showAddDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1B243B) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                ),
                                child: Center(
                                  child: Text(
                                    '+ Add Manually',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: exams.map((ex) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final examDay = DateTime(ex.examDate.year, ex.examDate.month, ex.examDate.day);
                      final daysLeft = examDay.difference(today).inDays;
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
                          date:
                              '${DateFormat('MMM dd').format(ex.examDate)} • ${ex.startTime}',
                          icon: Icons.school_outlined,
                          progress: ex.preparationProgress / 100.0,
                          onTap: () => _showAllExamsSheet(exams),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              SizedBox(height: 24),

              // Assignments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assignments & Tasks',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) =>
                        setState(() => _selectedPriority = val),
                    color: context.cardColor,
                    itemBuilder: (ctx) =>
                        ['All', 'High', 'Medium', 'Low'].map((p) {
                          return PopupMenuItem<String>(
                            value: p,
                            child: Text(
                              p,
                              style: TextStyle(color: textColor),
                            ),
                          );
                        }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B243B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedPriority,
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: subtextColor,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              if (filteredTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131A2B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          color: mutedTextColor,
                          size: 36,
                        ),
                        SizedBox(height: 10),
                        Text(
                          _searchController.text.trim().isNotEmpty
                              ? 'No tasks matching your search.'
                              : 'No plans yet. Create a task or add your timetable to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _showAddDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                  final subName =
                      subjects
                          .where((s) => s.id == t.subjectId)
                          .firstOrNull
                          ?.name ??
                      'General';
                  final tagColor = switch (t.priority.toLowerCase()) {
                    'high' => const Color(0xFFEF4444),
                    'low' => const Color(0xFF10B981),
                    _ => context.accentColor,
                  };

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A2B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
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
                              color: isDone
                                  ? const Color(0xFF10B981)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isDone
                                    ? Colors.transparent
                                    : (isDark ? Colors.white38 : Colors.black38),
                                width: 2,
                              ),
                            ),
                            child: isDone
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: TextStyle(
                                  color: isDone ? mutedTextColor : textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '$subName • ${DateFormat('MMM dd').format(t.dueDate)}',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 11,
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

              SizedBox(height: 24),

              // Daily Schedule Timeline
              Text(
                'Daily Schedule',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Schedule Conflicts Alert for Selected Date
              if (conflicts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: GestureDetector(
                    onTap: () => CalendarConflictDetailsSheet.show(
                      context,
                      conflicts: conflicts,
                      date: _selectedDate,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${conflicts.length} Schedule ${conflicts.length == 1 ? 'Conflict' : 'Conflicts'} Detected',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  conflicts.first.description,
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: subtextColor,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Public Holidays for Selected Date
              if (selectedDayHolidays.isNotEmpty)
                ...selectedDayHolidays.map((holiday) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: GestureDetector(
                      onTap: () =>
                          CalendarEventDetailsSheet.show(context, holiday),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.celebration_rounded,
                                color: Color(0xFFF59E0B),
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'PUBLIC HOLIDAY',
                                          style: TextStyle(
                                            color: Color(0xFFF59E0B),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        holiday.source,
                                        style: TextStyle(
                                          color: subtextColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    holiday.title,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: subtextColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              // Personal Google Calendar Events for Selected Date
              if (selectedPersonalEvents.isNotEmpty)
                ...selectedPersonalEvents.map((event) {
                  final timeFormat = DateFormat('h:mm a');
                  final timeStr = event.isAllDay
                      ? 'All day'
                      : '${timeFormat.format(event.startDateTime.toLocal())} - ${timeFormat.format(event.endDateTime.toLocal())}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: GestureDetector(
                      onTap: () =>
                          CalendarEventDetailsSheet.show(context, event),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF4285F4,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFF4285F4,
                            ).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF4285F4,
                                ).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_note_rounded,
                                color: Color(0xFF4285F4),
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF4285F4,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          timeStr,
                                          style: TextStyle(
                                            color: Color(0xFF7BD0FF),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        event.calendarName,
                                        style: TextStyle(
                                          color: subtextColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    event.title,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (event.location != null &&
                                      event.location!.isNotEmpty) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      event.location!,
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: subtextColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              if (dayClasses.isEmpty && selectedPersonalEvents.isEmpty)
                GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedDayHolidays.isNotEmpty
                              ? Icons.celebration_rounded
                              : Icons.calendar_today_outlined,
                          color: selectedDayHolidays.isNotEmpty
                              ? const Color(0xFFF59E0B)
                              : mutedTextColor,
                          size: 32,
                        ),
                        SizedBox(height: 12),
                        Text(
                          selectedDayHolidays.isNotEmpty
                              ? 'Public Holiday • ${selectedDayHolidays.first.title}'
                              : 'No classes or events scheduled today',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          selectedDayHolidays.isNotEmpty
                              ? 'Enjoy your holiday! No academic classes or personal events scheduled.'
                              : 'Add your timetable or connect Google Calendar to see your schedule.',
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...dayClasses.map((entry) {
                  final sub = subjects.cast<Subject?>().firstWhere(
                    (s) => s?.id == entry.subjectId,
                    orElse: () => null,
                  );
                  final facultyStr = sub?.facultyName.isNotEmpty == true
                      ? ' • ${sub!.facultyName}'
                      : '';
                  final roomStr = entry.room != null && entry.room!.isNotEmpty
                      ? 'Room ${entry.room}'
                      : 'Classroom';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _scheduleTimelineItem(
                      time:
                          '${entry.startTimeDisplay} - ${entry.endTimeDisplay}',
                      title: sub?.name ?? 'Scheduled Class',
                      subtitle: '$roomStr$facultyStr',
                    ),
                  );
                }),
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
                color: context.accentColor,
                boxShadow: [
                  BoxShadow(
                    color: context.accentColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
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
      child: GlassContainer(
        tier: GlassTier.standard,
        width: 220,
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  badge,
                  style: TextStyle(
                    color: Color(0xFFFF8B94),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Icon(icon, color: const Color(0xFF7BD0FF), size: 18),
              ],
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            SizedBox(height: 14),
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

  Widget _scheduleTimelineItem({
    required String time,
    required String title,
    required String subtitle,
  }) {
    final isDark = context.isDark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.accentColor,
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A2B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.subtextColor,
                        fontSize: 12,
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
