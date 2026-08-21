import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/calendar/providers/calendar_provider.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final _subjectNameController = TextEditingController();
  final _facultyController = TextEditingController();
  final _overrideController = TextEditingController();
  int _selectedColor = 0xFF5B5FEF; // Luminous Indigo base

  @override
  void dispose() {
    _subjectNameController.dispose();
    _facultyController.dispose();
    _overrideController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5B5FEF),
              surface: Color(0xFF131A2B),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0E131F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddSubjectDialog(String activeSemId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0E1628),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
                    const SizedBox(height: 18),
                    const Text(
                      'Add New Subject',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set up a course to start tracking your attendance.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Quick OCR Timetable Option
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/import-timetable');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B243B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF5B5FEF,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              color: Color(0xFF7BD0FF),
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scan & Auto-Import Timetable',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Upload timetable image to detect all subjects',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white38,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white12)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR ENTER MANUALLY',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: _subjectNameController,
                      labelText: 'Subject Name',
                      hintText: 'e.g. Organic Chemistry',
                    ),
                    const SizedBox(height: 14),
                    GlassTextField(
                      controller: _facultyController,
                      labelText: 'Faculty / Instructor Name',
                      hintText: 'e.g. Dr. Verma',
                    ),
                    const SizedBox(height: 14),
                    GlassTextField(
                      controller: _overrideController,
                      labelText: 'Target Attendance (%)',
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. 80 (Optional)',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Subject Color Theme',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          [
                            0xFF5B5FEF,
                            0xFF7BD0FF,
                            0xFF10B981,
                            0xFF8151EB,
                            0xFFF59E0B,
                            0xFFEF4444,
                          ].map((c) {
                            final isSelected = _selectedColor == c;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() => _selectedColor = c);
                                setState(() => _selectedColor = c);
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(c),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                      : Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Color(
                                              c,
                                            ).withValues(alpha: 0.5),
                                            blurRadius: 10,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white60,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
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
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Subject "$name" added successfully!',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5B5FEF),
                                    Color(0xFF8151EB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  'Save Subject',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
              ),
            );
          },
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
          date: _selectedDate,
          periodNumber: period,
          status: status,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            duration: const Duration(milliseconds: 2000),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        final dateLabel = _isSameDay(_selectedDate, DateTime.now())
            ? 'Today'
            : DateFormat('MMM dd').format(_selectedDate);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as ${status.toUpperCase()} for $dateLabel'),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _unmarkAttendance(String recordId, String subjectName) async {
    HapticFeedback.mediumImpact();
    await ref
        .read(attendanceRepositoryProvider.notifier)
        .deleteAttendance(recordId);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance cleared for $subjectName'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _toggleHolidayStatus() async {
    HapticFeedback.lightImpact();
    final wasHoliday = ref.read(isHolidayDateProvider(_selectedDate));
    await ref
        .read(calendarRepositoryProvider.notifier)
        .toggleHolidayForDate(_selectedDate);
    if (mounted) {
      final dateLabel = _isSameDay(_selectedDate, DateTime.now())
          ? 'Today'
          : DateFormat('MMM dd').format(_selectedDate);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasHoliday
                ? 'Switched $dateLabel to Working Day (Classes Active)'
                : 'Marked $dateLabel as College Holiday (Classes Suspended)',
          ),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _resetHolidayStatus() async {
    HapticFeedback.lightImpact();
    await ref
        .read(calendarRepositoryProvider.notifier)
        .resetHolidayOverride(_selectedDate);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reset to original calendar schedule'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = ref.watch(activeSemesterProvider);
    final stats = ref.watch(statsProvider);
    final allRecords = ref.watch(attendanceRepositoryProvider);

    if (activeSem == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    color: Colors.white38,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
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
                    'Create an active semester to start logging attendance.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.push('/semester-manage'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Manage Semesters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Records for the selected date
    final dateRecords = allRecords
        .where((r) => _isSameDay(r.date, _selectedDate))
        .toList();

    final allHolidays = ref.watch(calendarRepositoryProvider);
    final selectedHolidays = ref.watch(
      holidaysForSelectedDateProvider(_selectedDate),
    );
    final isEffectiveHoliday = ref.watch(isHolidayDateProvider(_selectedDate));
    final isOverridden = ref.watch(isHolidayOverriddenProvider(_selectedDate));

    // Generate 7-day strip centered on selected date
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final monthYearFormatted = DateFormat('MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1B243B),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: Color(0xFFC0C1FF),
              size: 18,
            ),
          ),
        ),
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeSem.name.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF908FA0),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              'Attendance Log',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.document_scanner_rounded,
              color: Color(0xFF7BD0FF),
              size: 22,
            ),
            tooltip: 'Upload / Scan Timetable Photo',
            onPressed: () => context.push('/import-timetable'),
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFFC0C1FF),
              size: 24,
            ),
            tooltip: 'Pick Any Date to Mark Attendance',
            onPressed: _pickDate,
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Add Subject',
            onPressed: () => _showAddSubjectDialog(activeSem.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
        children: [
          // 1. Calendar Header & Date Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    monthYearFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isToday) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDate = DateTime.now()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF5B5FEF,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              color: Color(0xFF7BD0FF),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Jump to Today',
                              style: TextStyle(
                                color: Color(0xFFC0C1FF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white70,
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
                  const SizedBox(width: 14),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
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
          const SizedBox(height: 14),

          // 2. Horizontal Date Selector Strip (With Holiday Indicators)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays.map((day) {
              final isSelected = _isSameDay(day, _selectedDate);
              final isActualToday = _isSameDay(day, DateTime.now());
              final isHolidayDay = allHolidays.any(
                (h) => h.occursOn(day) && h.isHolidayOrFestival,
              );
              final dayName = DateFormat('E').format(day).toUpperCase();
              final dayNumber = day.day.toString();

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = day),
                child: Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFC0C1FF)
                        : isActualToday
                        ? const Color(0xFF1B243B)
                        : const Color(0xFF131A2B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isHolidayDay
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                          : isActualToday
                          ? const Color(0xFF5B5FEF).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0E00AA)
                              : isHolidayDay
                              ? const Color(0xFFF59E0B)
                              : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayNumber,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0E00AA)
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isHolidayDay) ...[
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0E00AA)
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
          const SizedBox(height: 18),

          // 3. Selected Date Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEffectiveHoliday
                          ? Icons.celebration_rounded
                          : Icons.event_note_rounded,
                      color: isEffectiveHoliday
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF7BD0FF),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy',
                          ).format(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            Builder(
                              builder: (context) {
                                final now = DateTime.now();
                                final todayNorm = DateTime(now.year, now.month, now.day);
                                final selNorm = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                                final diff = selNorm.difference(todayNorm).inDays;
                                final relStr = diff == 0
                                    ? 'Today'
                                    : diff == -1
                                    ? 'Yesterday'
                                    : diff == 1
                                    ? 'Tomorrow'
                                    : diff < -1
                                    ? '${-diff} Days Ago'
                                    : 'In $diff Days';

                                return Text(
                                  isEffectiveHoliday
                                      ? 'College Holiday • $relStr'
                                      : 'Logging for $relStr',
                                  style: TextStyle(
                                    color: isEffectiveHoliday
                                        ? const Color(0xFFF59E0B)
                                        : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: isEffectiveHoliday
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                );
                              },
                            ),
                            if (isOverridden) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Custom',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FEF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.edit_calendar_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3.1 Prominent Public Holiday / College Off Card with Interactive Toggle
          if (selectedHolidays.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...selectedHolidays.map((holiday) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.16),
                      const Color(0xFFB45309).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.celebration_rounded,
                            color: Color(0xFFF59E0B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'COLLEGE HOLIDAY',
                                      style: TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      holiday.source,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                holiday.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'College is closed today. Regular classes are not scheduled.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'College is conducting classes today?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleHolidayStatus,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF10B981),
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Set as Working Day',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            // Quick toggle option to declare a custom college holiday if needed
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isOverridden)
                    GestureDetector(
                      onTap: _resetHolidayStatus,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A2B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restart_alt_rounded,
                              color: Colors.white54,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Reset to Default',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  GestureDetector(
                    onTap: _toggleHolidayStatus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.beach_access_rounded,
                            color: Color(0xFFF59E0B),
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Mark as College Holiday',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // 4. Subjects List (Integrated with Today's Timetable Schedule)
          if (stats.allSubjectStats.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      color: Colors.white24,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Subjects Added Yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Upload your timetable photo to automatically populate classes & schedule.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/import-timetable'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.document_scanner_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '📸 Scan Timetable',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showAddSubjectDialog(activeSem.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131A2B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text(
                              '+ Add Manually',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Check if there are scheduled entries on the timetable for this day
            Builder(
              builder: (context) {
                final timetableEntries = ref.watch(timetableRepositoryProvider);
                final dayOfWeek = _selectedDate.weekday;
                final scheduledEntries = timetableEntries
                    .where(
                      (e) =>
                          e.dayOfWeek == dayOfWeek &&
                          e.semesterId == activeSem.id &&
                          e.isEnabled,
                    )
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

                if (scheduledEntries.isNotEmpty) {
                  final scheduledSubjectIds = scheduledEntries
                      .map((e) => e.subjectId)
                      .toSet();
                  final otherStats = stats.allSubjectStats
                      .where((s) => !scheduledSubjectIds.contains(s.subject.id))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10.0,
                          left: 4,
                          right: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${DateFormat('EEEE').format(_selectedDate).toUpperCase()}'S SCHEDULE (${scheduledEntries.length})",
                              style: const TextStyle(
                                color: Color(0xFFC0C1FF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/import-timetable'),
                              child: const Text(
                                'Edit Schedule',
                                style: TextStyle(
                                  color: Color(0xFF7BD0FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Scheduled classes
                      ...scheduledEntries.map((entry) {
                        final stat = stats.allSubjectStats.cast<SubjectStats?>().firstWhere(
                          (s) => s != null && s.subject.id == entry.subjectId,
                          orElse: () => null,
                        );
                        if (stat != null) {
                          return _buildSubjectCard(
                            stat,
                            dateRecords,
                            activeSem.id,
                            scheduledEntry: entry,
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Other subjects not scheduled today
                      if (otherStats.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10.0,
                            left: 4,
                            right: 4,
                          ),
                          child: Text(
                            'OTHER SEMESTER COURSES (${otherStats.length})',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        ...otherStats.map(
                          (stat) => _buildSubjectCard(
                            stat,
                            dateRecords,
                            activeSem.id,
                          ),
                        ),
                      ],
                    ],
                  );
                } else {
                  // No specific timetable schedule for this day
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10.0,
                          left: 4,
                          right: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ALL SUBJECTS (${stats.allSubjectStats.length})',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/import-timetable'),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Color(0xFF7BD0FF),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Scan Schedule',
                                    style: TextStyle(
                                      color: Color(0xFF7BD0FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...stats.allSubjectStats.map(
                        (stat) => _buildSubjectCard(
                          stat,
                          dateRecords,
                          activeSem.id,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    SubjectStats item,
    List<AttendanceRecord> dateRecords,
    String semesterId, {
    TimetableEntry? scheduledEntry,
  }) {
    final sub = item.subject;
    final subjectRecords = dateRecords
        .where((r) => r.subjectId == sub.id)
        .toList();
    final hasRecord = subjectRecords.isNotEmpty;
    final lastRecord = hasRecord ? subjectRecords.first : null;
    final isPresent = lastRecord?.status == 'present';
    final isAbsent = lastRecord?.status == 'absent';

    final pct = item.percentage;
    final pctColor = pct >= item.target
        ? const Color(0xFF10B981)
        : pct >= 60
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => context.push('/subject-detail/${sub.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131A2B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasRecord
                  ? (isPresent
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.4)
                  : scheduledEntry != null
                  ? const Color(0xFF5B5FEF).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              if (scheduledEntry != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(
                            0xFF5B5FEF,
                          ).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'PERIOD ${scheduledEntry.periodNumber} • ${scheduledEntry.startTimeDisplay} - ${scheduledEntry.endTimeDisplay}',
                        style: const TextStyle(
                          color: Color(0xFFC0C1FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (scheduledEntry.room != null &&
                        scheduledEntry.room!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white60,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              scheduledEntry.room!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(sub.colorValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub.facultyName.isNotEmpty
                              ? 'Prof. ${sub.facultyName}'
                              : 'Instructor not set',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: pctColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Target: ${item.target.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 12),

              // Action Buttons for this date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasRecord)
                    Row(
                      children: [
                        Icon(
                          isPresent
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isPresent
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isPresent ? 'Logged: Present' : 'Logged: Absent',
                                  style: TextStyle(
                                    color: isPresent
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (lastRecord != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _unmarkAttendance(
                                      lastRecord.id,
                                      sub.name,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white60,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (lastRecord != null)
                              Builder(
                                builder: (context) {
                                  final ts = lastRecord.updatedAt > 0
                                      ? lastRecord.updatedAt
                                      : lastRecord.createdAt;
                                  final dt = ts > 0
                                      ? DateTime.fromMillisecondsSinceEpoch(ts)
                                      : lastRecord.date;
                                  return Text(
                                    'Marked at ${DateFormat('hh:mm a').format(dt)}',
                                    style: const TextStyle(
                                      color: Color(0xFF7BD0FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Not Logged Yet',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  Row(
                    children: [
                      // Present Button (Taps toggle off if already marked)
                      GestureDetector(
                        onTap: () {
                          if (isPresent && lastRecord != null) {
                            _unmarkAttendance(lastRecord.id, sub.name);
                          } else {
                            _mark(
                              semesterId,
                              sub.id,
                              'present',
                              scheduledEntry?.periodNumber,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? const Color(0xFF10B981)
                                : const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPresent
                                  ? Colors.transparent
                                  : const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: isPresent
                                    ? Colors.black
                                    : const Color(0xFF10B981),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Present',
                                style: TextStyle(
                                  color: isPresent
                                      ? Colors.black
                                      : const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Absent Button (Taps toggle off if already marked)
                      GestureDetector(
                        onTap: () {
                          if (isAbsent && lastRecord != null) {
                            _unmarkAttendance(lastRecord.id, sub.name);
                          } else {
                            _mark(
                              semesterId,
                              sub.id,
                              'absent',
                              scheduledEntry?.periodNumber,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isAbsent
                                ? const Color(0xFFEF4444)
                                : const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isAbsent
                                  ? Colors.transparent
                                  : const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: isAbsent
                                    ? Colors.white
                                    : const Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Absent',
                                style: TextStyle(
                                  color: isAbsent
                                      ? Colors.white
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
