import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class SemesterManageScreen extends ConsumerStatefulWidget {
  const SemesterManageScreen({super.key});

  @override
  ConsumerState<SemesterManageScreen> createState() =>
      _SemesterManageScreenState();
}

class _SemesterManageScreenState extends ConsumerState<SemesterManageScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddSemesterSheet() {
    _nameController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: ctx.isDark ? const Color(0xFF0E1628) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: ctx.subtleBorderColor),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'New Semester',
                style: TextStyle(
                  color: ctx.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter a name for your new semester.',
                style: TextStyle(
                  color: ctx.subtextColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              GlassTextField(
                controller: _nameController,
                labelText: 'Semester Name',
                hintText: 'e.g. Fall 2026',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      await ref
                          .read(semesterRepositoryProvider.notifier)
                          .createSemester(name, null, DateTime.now(), null);
                      _nameController.clear();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF5B5FEF,
                          ).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Create Semester',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSemester(BuildContext context, String semId, String semName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: ctx.isDark ? const Color(0xFF0E1628) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: ctx.subtleBorderColor),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Semester',
                  style: TextStyle(
                    color: ctx.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "$semName"? This will remove all associated subjects and attendance data. This action cannot be undone.',
                  style: TextStyle(color: ctx.subtextColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ctx.textColor,
                          side: BorderSide(color: ctx.subtleBorderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(semesterRepositoryProvider.notifier)
                              .deleteSemester(semId);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, Subject subject, String semName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: ctx.isDark ? const Color(0xFF0E1628) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: ctx.subtleBorderColor),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFEF4444),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Subject',
                  style: TextStyle(
                    color: ctx.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${subject.name}" from $semName?\n\nAll attendance records, timetable slots, topics, and study logs for this subject will be permanently removed.',
                  style: TextStyle(color: ctx.subtextColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ctx.textColor,
                          side: BorderSide(color: ctx.subtleBorderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(subjectRepositoryProvider.notifier)
                              .deleteSubject(subject.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Subject "${subject.name}" deleted.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(semesterRepositoryProvider);
    final allSubjects = ref.watch(subjectRepositoryProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: context.textColor,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Semesters & Subjects',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _showAddSemesterSheet,
                child: GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(8),
                  borderColor: context.subtleBorderColor,
                  child: Icon(
                    Icons.add_rounded,
                    color: context.textColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 56,
                      color: context.mutedTextColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Semesters Yet',
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create your first semester.',
                      style: TextStyle(
                        color: context.mutedTextColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _showAddSemesterSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF5B5FEF,
                              ).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Add Semester',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final sem = list[index];
                  final semSubjects =
                      allSubjects.where((s) => s.semesterId == sem.id).toList();
                  return GlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(18),
                    borderColor: sem.isActive
                        ? const Color(0xFF5B5FEF).withValues(alpha: 0.4)
                        : context.subtleBorderColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Semester Header Row
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: sem.isActive
                                    ? const Color(
                                        0xFF5B5FEF,
                                      ).withValues(alpha: 0.15)
                                    : (context.isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sem.isActive
                                      ? const Color(
                                          0xFF5B5FEF,
                                        ).withValues(alpha: 0.4)
                                      : context.subtleBorderColor,
                                ),
                              ),
                              child: Icon(
                                sem.isActive
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.calendar_today_outlined,
                                color: sem.isActive
                                    ? const Color(0xFF5B5FEF)
                                    : context.mutedTextColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sem.name,
                                    style: TextStyle(
                                      color: context.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sem.isActive
                                          ? const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.15)
                                          : (context.isDark
                                              ? Colors.white.withValues(alpha: 0.06)
                                              : Colors.black.withValues(alpha: 0.06)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      sem.isActive ? 'ACTIVE' : 'ARCHIVED',
                                      style: TextStyle(
                                        color: sem.isActive
                                            ? const Color(0xFF10B981)
                                            : context.mutedTextColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (!sem.isActive)
                                  Tooltip(
                                    message: 'Set Active',
                                    child: GestureDetector(
                                      onTap: () => ref
                                          .read(semesterRepositoryProvider.notifier)
                                          .setActiveSemester(sem.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Color(0xFF10B981),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Delete Semester',
                                  child: GestureDetector(
                                    onTap: () =>
                                        _confirmDeleteSemester(context, sem.id, sem.name),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Subjects Section
                        const SizedBox(height: 16),
                        Divider(color: context.subtleBorderColor, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 14,
                                  color: context.subtextColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${semSubjects.length} Subject${semSubjects.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    color: context.subtextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (semSubjects.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No subjects enrolled in this semester yet.',
                              style: TextStyle(
                                color: context.mutedTextColor,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: semSubjects.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, sIdx) {
                              final sub = semSubjects[sIdx];
                              final subColor = Color(sub.colorValue);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: context.isDark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.subtleBorderColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Color Dot Indicator
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: subColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: subColor.withValues(alpha: 0.5),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Subject Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.name,
                                            style: TextStyle(
                                              color: context.textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              if (sub.code != null && sub.code!.isNotEmpty) sub.code!,
                                              if (sub.facultyName.isNotEmpty) sub.facultyName,
                                              'Target: ${sub.targetAttendance.toInt()}%',
                                            ].join(' • '),
                                            style: TextStyle(
                                              color: context.mutedTextColor,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Delete Subject Action Button
                                    Tooltip(
                                      message: 'Delete ${sub.name}',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Color(0xFFEF4444),
                                        ),
                                        onPressed: () => _confirmDeleteSubject(
                                          context,
                                          sub,
                                          sem.name,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
