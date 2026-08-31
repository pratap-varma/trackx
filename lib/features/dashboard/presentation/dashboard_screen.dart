import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/routing/nav_provider.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/providers/timetable_provider.dart';
import 'package:trackx/features/notes/providers/flashcard_provider.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/sync_status_badge.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  void _showBunkCalculatorSheet(
    int safeBunks,
    String subjectName,
    double target,
  ) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0E1628) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF475569);

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
                const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF7BD0FF),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Bunk Risk Calculator',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You can safely skip $safeBunks more classes in $subjectName while remaining above your target threshold of ${target.toInt()}%.',
              style: TextStyle(color: subtextColor, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(navIndexProvider.notifier).state =
                      1; // Jump to Attendance
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'View Subject Attendance Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectsAttendanceSheet(SemesterStats stats) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0E1628) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF475569);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.subject_rounded,
                    color: Color(0xFFC0C1FF),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Subject Attendance',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (stats.allSubjectStats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No subjects added yet.',
                    style: TextStyle(color: subtextColor),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: stats.allSubjectStats.length,
                    itemBuilder: (ctx, idx) {
                      final sStat = stats.allSubjectStats[idx];
                      final s = sStat.subject;
                      final p = sStat.percentage;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    s.name,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${p.toInt()}%',
                                  style: TextStyle(
                                    color: p >= sStat.target
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFFF8B94),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: p / 100,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation(
                                  p >= sStat.target
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFFF8B94),
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${sStat.presentCount} / ${sStat.totalCount} classes attended',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authRepositoryProvider);
    final profile = authState.userProfile;
    final name = profile?.name.isNotEmpty == true
        ? profile!.name.split(' ').first
        : 'Student';

    final activeSem = ref.watch(activeSemesterProvider);
    final stats = ref.watch(statsProvider);
    final subjects = ref.watch(subjectRepositoryProvider);
    final currentClass = ref.watch(currentClassProvider);
    final nextClass = ref.watch(nextClassProvider);
    final todayTimetable = ref.watch(todayTimetableProvider);

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    final pct = stats.overallPercentage;
    final target = stats.globalTarget;
    final activeClass = currentClass ?? nextClass;
    final activeSubject = activeClass != null
        ? subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == activeClass.subjectId,
            orElse: () => null,
          )
        : null;

    final currentSubject = currentClass != null
        ? subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == currentClass.subjectId,
            orElse: () => null,
          )
        : null;

    final nextSubject = nextClass != null
        ? subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == nextClass.subjectId,
            orElse: () => null,
          )
        : null;

    SubjectStats? focusSubjectStats;
    if (activeSubject != null) {
      focusSubjectStats = stats.allSubjectStats.cast<SubjectStats?>().firstWhere(
            (s) => s?.subject.id == activeSubject.id,
            orElse: () => null,
          );
    }
    if (focusSubjectStats == null && stats.highestRiskSubjectName != null) {
      focusSubjectStats = stats.allSubjectStats.cast<SubjectStats?>().firstWhere(
            (s) => s?.subject.name == stats.highestRiskSubjectName,
            orElse: () => null,
          );
    }
    if (focusSubjectStats == null && stats.allSubjectStats.isNotEmpty) {
      focusSubjectStats = stats.allSubjectStats.first;
    }

    final safeBunks = focusSubjectStats?.safeBunks ?? 0;
    final requiredRecovery = focusSubjectStats?.requiredRecovery ?? 0;
    final isDeficit = requiredRecovery > 0;
    final bunkFocusName = focusSubjectStats?.subject.name ?? 'your classes';
    final bunkTarget = focusSubjectStats?.target ?? target;

    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFDEE2F4) : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final mutedTextColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'TrackX',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        key: const PageStorageKey('dashboard_list_scroll'),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'DASHBOARD',
                style: TextStyle(
                  color: Color(0xFF908FA0),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SyncStatusBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$greeting, $name!',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),

          // FLASHCARDS & SPACED REPETITION DUE TODAY BANNER
          Consumer(
            builder: (context, ref, _) {
              final dueCount = ref.watch(dueFlashcardsCountProvider);
              final decks = ref.watch(flashcardsProvider);
              if (decks.isEmpty && dueCount == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/flashcards');
                  },
                  child: GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    borderColor: dueCount > 0
                        ? const Color(0xFF5B5FEF).withValues(alpha: 0.5)
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (dueCount > 0
                                    ? const Color(0xFF5B5FEF)
                                    : const Color(0xFF10B981))
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            dueCount > 0
                                ? Icons.alarm_rounded
                                : Icons.check_circle_outline_rounded,
                            color: dueCount > 0
                                ? const Color(0xFFC0C1FF)
                                : const Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dueCount > 0
                                    ? '$dueCount Flashcard${dueCount > 1 ? "s" : ""} Due Today'
                                    : 'Flashcards Reviewed',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                dueCount > 0
                                    ? 'Tap to start your spaced-repetition session'
                                    : '${decks.length} active deck${decks.length > 1 ? "s" : ""} • All caught up',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: mutedTextColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // HAPPENING NOW / CLASS SCHEDULE CARD
          Builder(
            builder: (context) {
              if (currentClass != null) {
                // Ongoing class right now
                final subName = currentSubject?.name ?? 'Ongoing Class';
                final roomText = (currentClass.room != null && currentClass.room!.isNotEmpty)
                    ? 'Room ${currentClass.room}'
                    : 'Classroom';
                final facultyText = currentSubject?.facultyName.isNotEmpty == true
                    ? ' • ${currentSubject!.facultyName}'
                    : '';
                final timeText = '${currentClass.startTimeDisplay} - ${currentClass.endTimeDisplay}';

                return GlassContainer(
                  tier: GlassTier.standard,
                  borderRadius: 20,
                  borderColor: const Color(0xFFFF8B94).withValues(alpha: 0.6),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF8B94),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'HAPPENING NOW',
                            style: TextStyle(
                              color: Color(0xFFFF8B94),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: subtextColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$roomText • $timeText$facultyText',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Builder(
                        builder: (context) {
                          final subId = currentClass.subjectId;
                          final allRecords = ref.watch(attendanceRepositoryProvider);
                          final now = DateTime.now();
                          final todayRecords = allRecords
                              .where(
                                (r) =>
                                    r.subjectId == subId &&
                                    r.date.year == now.year &&
                                    r.date.month == now.month &&
                                    r.date.day == now.day,
                              )
                              .toList();
                          
                          AttendanceRecord? todayRecord;
                          if (currentClass.periodNumber > 0) {
                            todayRecord = todayRecords
                                .cast<AttendanceRecord?>()
                                .firstWhere(
                                  (r) => r?.periodNumber == currentClass.periodNumber,
                                  orElse: () => null,
                                );
                          }
                          todayRecord ??= todayRecords.firstOrNull;
                          final isMarkedToday = todayRecord != null;
                          final isPresent = todayRecord?.status == 'present';

                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                if (activeSem != null) {
                                  if (isMarkedToday) {
                                    ref
                                        .read(attendanceRepositoryProvider.notifier)
                                        .deleteAttendance(todayRecord!.id);
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Attendance record cleared for current class!',
                                        ),
                                        duration: const Duration(milliseconds: 1500),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(
                                          bottom: 90,
                                          left: 16,
                                          right: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ref
                                        .read(attendanceRepositoryProvider.notifier)
                                        .markAttendance(
                                          userId: profile?.id ?? 'user',
                                          semesterId: activeSem.id,
                                          subjectId: subId,
                                          date: DateTime.now(),
                                          periodNumber: currentClass.periodNumber,
                                          status: 'present',
                                        );
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Attendance marked present for $subName!',
                                        ),
                                        duration: const Duration(milliseconds: 1500),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(
                                          bottom: 90,
                                          left: 16,
                                          right: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: Icon(
                                isMarkedToday
                                    ? (isPresent
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded)
                                    : Icons.pin_drop_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isMarkedToday
                                    ? (isPresent
                                        ? 'Marked Present (Tap to Undo)'
                                        : 'Marked Absent (Tap to Undo)')
                                    : 'Mark Present for Class',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isMarkedToday
                                    ? (isPresent
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444))
                                    : const Color(0xFF5B5FEF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              } else if (nextClass != null) {
                // Upcoming class scheduled later today
                final subName = nextSubject?.name ?? 'Upcoming Class';
                final roomText = (nextClass.room != null && nextClass.room!.isNotEmpty)
                    ? 'Room ${nextClass.room}'
                    : 'Classroom';
                final facultyText = nextSubject?.facultyName.isNotEmpty == true
                    ? ' • ${nextSubject!.facultyName}'
                    : '';

                return GlassContainer(
                  tier: GlassTier.standard,
                  borderRadius: 20,
                  borderColor: const Color(0xFF7BD0FF).withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF7BD0FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'UPCOMING NEXT',
                            style: TextStyle(
                              color: Color(0xFF7BD0FF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: subtextColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Starts at ${nextClass.startTimeDisplay} (${nextClass.startTimeDisplay} - ${nextClass.endTimeDisplay}) • $roomText$facultyText',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(navIndexProvider.notifier).state = 2; // Planner
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: const Text(
                            'View Full Timetable',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7BD0FF),
                            side: const BorderSide(color: Color(0xFF7BD0FF)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (todayTimetable.isNotEmpty) {
                // All classes scheduled for today completed
                return GlassContainer(
                  tier: GlassTier.standard,
                  borderRadius: 20,
                  borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ALL CLASSES COMPLETED',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No Classes Scheduled Now',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF10B981),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'All ${todayTimetable.length} classes scheduled for today have ended.',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(navIndexProvider.notifier).state = 2; // Planner
                          },
                          icon: const Icon(Icons.event_note_rounded, size: 18),
                          label: const Text(
                            'View Today\'s Timetable',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                            side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // No classes scheduled today
                return GlassContainer(
                  tier: GlassTier.standard,
                  borderRadius: 20,
                  borderColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF908FA0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SCHEDULE',
                            style: TextStyle(
                              color: Color(0xFF908FA0),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No Classes Scheduled Today',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: subtextColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subjects.isNotEmpty
                                  ? 'No classes on your timetable for today. Enjoy your day!'
                                  : 'Add subjects and timetable in Planner to track classes.',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(navIndexProvider.notifier).state = 2; // Planner
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: Text(
                            subjects.isNotEmpty ? 'View Timetable' : 'Add Timetable',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC0C1FF),
                            side: const BorderSide(color: Color(0xFF5B5FEF)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 14),

          // 3. ATTENDANCE GAUGE CARD (Interactive)
          GestureDetector(
            onTap: () => _showSubjectsAttendanceSheet(stats),
            child: GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ATTENDANCE',
                        style: TextStyle(
                          color: Color(0xFF908FA0),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: mutedTextColor,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            ref.read(navIndexProvider.notifier).state = 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: _AttendanceGaugePainter(percentage: pct / 100, isDark: isDark),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${pct.toInt()}%',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Avg',
                                style: TextStyle(
                                  color: mutedTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. SAFE-TO-BUNK STATUS CARD (Interactive)
          GestureDetector(
            onTap: () =>
                _showBunkCalculatorSheet(safeBunks, bunkFocusName, target),
            child: GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF7BD0FF),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SAFE-TO-BUNK STATUS',
                            style: TextStyle(
                              color: Color(0xFF7BD0FF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: mutedTextColor,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      children: isDeficit 
                        ? [
                            const TextSpan(text: 'You need to attend '),
                            TextSpan(
                              text: '$requiredRecovery more',
                              style: const TextStyle(
                                color: Color(0xFFFF8B94),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' classes'),
                          ]
                        : [
                            const TextSpan(text: 'You can skip '),
                            TextSpan(
                              text: '$safeBunks more',
                              style: const TextStyle(
                                color: Color(0xFF7BD0FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' classes'),
                          ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'in $bunkFocusName to stay above the ${bunkTarget.toInt()}% threshold.',
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: isDeficit ? (requiredRecovery / 10.0).clamp(0.0, 1.0) : (safeBunks / 10.0).clamp(0.0, 1.0),
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation(
                              isDeficit ? const Color(0xFFFF8B94) : const Color(0xFF7BD0FF),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isDeficit ? 'Deficit' : 'Buffer',
                        style: TextStyle(color: mutedTextColor, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 5. AI SMART BRIEF CARD (Interactive)
          GestureDetector(
            onTap: () =>
                ref.read(navIndexProvider.notifier).state = 3, // Jump to AI
            child: GlassContainer(
              tier: GlassTier.standard,
              borderRadius: 20,
              borderColor: const Color(0xFF5B5FEF).withValues(alpha: 0.4),
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFFC0C1FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI SMART BRIEF ⚡',
                          style: TextStyle(
                            color: Color(0xFFC0C1FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontSize: 13,
                              height: 1.4,
                            ),
                            children: stats.totalRecorded == 0
                                ? const [
                                    TextSpan(
                                      text:
                                          'Your schedule is clear! Add your timetable to get daily AI insights, class reminders, and attendance forecasts.',
                                    ),
                                  ]
                                : [
                                    const TextSpan(
                                      text:
                                          'Based on your attendance trend, prioritizing ',
                                    ),
                                    TextSpan(
                                      text:
                                          stats.highestRiskSubjectName ??
                                          bunkFocusName,
                                      style: const TextStyle(
                                        color: Color(0xFFD0BCFF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' will help maintain your academic target margin.',
                                    ),
                                  ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 6. REMAINING TODAY
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5FEF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remaining Today',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          () {
            final nowMinutes = now.hour * 60 + now.minute;
            final remainingClasses =
                todayTimetable.where((e) => e.startTime > nowMinutes).toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

            if (remainingClasses.isEmpty) {
              return GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    todayTimetable.isEmpty
                        ? 'No classes scheduled today'
                        : 'All classes for today completed 🎉',
                    style: TextStyle(color: subtextColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final colors = [
              const Color(0xFFC0C1FF),
              const Color(0xFF8151EB),
              const Color(0xFF7BD0FF),
              const Color(0xFF10B981),
            ];

            return Column(
              children: remainingClasses.asMap().entries.map((item) {
                final idx = item.key;
                final entry = item.value;
                final sub = subjects.cast<Subject?>().firstWhere(
                  (s) => s?.id == entry.subjectId,
                  orElse: () => null,
                );
                final color = colors[idx % colors.length];
                final facultyStr = sub?.facultyName.isNotEmpty == true
                    ? ' • ${sub!.facultyName}'
                    : '';
                final roomStr = entry.room != null && entry.room!.isNotEmpty
                    ? 'Room ${entry.room}'
                    : 'Classroom';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => ref.read(navIndexProvider.notifier).state = 1,
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub?.name ?? 'Scheduled Class',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$roomStr$facultyStr',
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            entry.startTimeDisplay,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }(),
        ],
      ),
    );
  }
}

class _AttendanceGaugePainter extends CustomPainter {
  final double percentage;
  final bool isDark;

  _AttendanceGaugePainter({required this.percentage, this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3 * pi / 4,
      3 * pi / 2,
      false,
      bgPaint,
    );

    final fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5B5FEF), Color(0xFF7BD0FF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (3 * pi / 2) * percentage.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3 * pi / 4,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AttendanceGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.isDark != isDark;
  }
}
