import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/routing/nav_provider.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/providers/timetable_provider.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _showAiScoreSheet(
    int score,
    String rating,
    double attendanceConsistency,
    double targetBuffer,
    double classParticipation,
  ) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B5FEF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Readiness Score',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          rating,
                          style: const TextStyle(
                            color: Color(0xFF7BD0FF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  score > 0 ? '$score' : '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _scoreBar(
              'Attendance Consistency',
              attendanceConsistency,
              const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _scoreBar(
              'Target Adherence',
              targetBuffer,
              const Color(0xFF5B5FEF),
            ),
            const SizedBox(height: 12),
            _scoreBar(
              'Class Participation',
              classParticipation,
              const Color(0xFF7BD0FF),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(navIndexProvider.notifier).state =
                      3; // Jump to AI Assistant
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
                  'Get AI Recommendations',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBunkCalculatorSheet(
    int safeBunks,
    String subjectName,
    double target,
  ) {
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
            const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF7BD0FF),
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Bunk Risk Calculator',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You can safely skip $safeBunks more classes in $subjectName while remaining above your target threshold of ${target.toInt()}%.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
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

  static Widget _scoreBar(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${(val * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
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
    final safeBunks = max(
      0,
      ((stats.totalPresent - (target / 100.0 * stats.totalRecorded)) / 1.0)
          .floor(),
    );

    final int aiScore;
    final String aiScoreRating;
    final double attendanceConsistency;
    final double targetBuffer;
    final double classParticipation;

    if (stats.totalRecorded == 0) {
      aiScore = 0;
      aiScoreRating = 'New Account';
      attendanceConsistency = 0.0;
      targetBuffer = 0.0;
      classParticipation = 0.0;
    } else {
      aiScore = pct.round().clamp(0, 100);
      aiScoreRating = aiScore >= 90
          ? 'Excellent'
          : aiScore >= 75
          ? 'Good'
          : aiScore >= 60
          ? 'Fair'
          : 'Needs Attention';
      attendanceConsistency = (pct / 100.0).clamp(0.0, 1.0);
      targetBuffer = (pct / max(1.0, target)).clamp(0.0, 1.0);
      classParticipation = min(
        1.0,
        stats.totalRecorded / max(1.0, subjects.length * 10.0),
      );
    }

    final activeClass = currentClass ?? nextClass;
    final activeSubject = activeClass != null
        ? subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == activeClass.subjectId,
            orElse: () => null,
          )
        : null;
    final activeSubjectName =
        activeSubject?.name ??
        (currentClass != null
            ? 'Scheduled Class'
            : (nextClass != null
                  ? 'Upcoming Class'
                  : (todayTimetable.isNotEmpty
                        ? 'No Ongoing Class'
                        : 'No Classes Scheduled')));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          onPressed: () {
            ref.read(navIndexProvider.notifier).state = 4; // Profile
          },
        ),
        title: const Text(
          'TrackX',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFC0C1FF),
              size: 22,
            ),
            onPressed: () {
              ref.read(navIndexProvider.notifier).state = 3; // AI Assistant
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
        children: [
          const Text(
            'DASHBOARD',
            style: TextStyle(
              color: Color(0xFF908FA0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$greeting, $name!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),

          // 1. AI SCORE CARD (Interactive)
          GestureDetector(
            onTap: () => _showAiScoreSheet(
              aiScore,
              aiScoreRating,
              attendanceConsistency,
              targetBuffer,
              classParticipation,
            ),
            child: GlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFC0C1FF),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'AI SCORE',
                              style: TextStyle(
                                color: Color(0xFF908FA0),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          aiScoreRating,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        aiScore > 0 ? '$aiScore' : '--',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. HAPPENING NOW CARD
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131A2B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF5B5FEF).withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentClass != null
                            ? const Color(0xFFFF8B94)
                            : const Color(0xFF7BD0FF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentClass != null ? 'HAPPENING NOW' : 'SCHEDULE',
                      style: TextStyle(
                        color: currentClass != null
                            ? const Color(0xFFFF8B94)
                            : const Color(0xFF7BD0FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  activeSubjectName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        currentClass != null
                            ? '${currentClass.room ?? "Classroom"} • ${currentClass.startTimeDisplay} - ${currentClass.endTimeDisplay}'
                            : (subjects.isNotEmpty
                                  ? 'Next class will appear when scheduled'
                                  : 'Add subjects and timetable to track classes'),
                        style: const TextStyle(
                          color: Colors.white60,
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
                    final subId = currentClass?.subjectId ?? (subjects.isNotEmpty ? subjects.first.id : null);
                    final allRecords = ref.watch(attendanceRepositoryProvider);
                    final now = DateTime.now();
                    final matchingRecords = subId == null
                        ? <dynamic>[]
                        : allRecords
                            .where(
                              (r) =>
                                  r.subjectId == subId &&
                                  r.date.year == now.year &&
                                  r.date.month == now.month &&
                                  r.date.day == now.day &&
                                  (currentClass != null
                                      ? (r.periodNumber == currentClass.periodNumber ||
                                          (r.periodNumber == null &&
                                              allRecords
                                                      .where(
                                                        (x) =>
                                                            x.subjectId == subId &&
                                                            x.date.year == now.year &&
                                                            x.date.month == now.month &&
                                                            x.date.day == now.day,
                                                      )
                                                      .length ==
                                                  1))
                                      : true),
                            )
                            .toList();
                    final todayRecord = matchingRecords.isNotEmpty ? matchingRecords.first : null;
                    final isMarkedToday = todayRecord != null;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (activeSem != null && subjects.isNotEmpty && subId != null) {
                            if (isMarkedToday) {
                              // Delete/Unmark accidental mark
                              ref
                                  .read(attendanceRepositoryProvider.notifier)
                                  .deleteAttendance(todayRecord.id);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Attendance record cleared for today!',
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
                                    userId: profile?.id ?? 'u1',
                                    semesterId: activeSem.id,
                                    subjectId: subId,
                                    date: DateTime.now(),
                                    periodNumber: currentClass?.periodNumber,
                                    status: 'present',
                                  );
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Attendance Marked as Present for Current Class!',
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
                          } else {
                            ref.read(navIndexProvider.notifier).state = 1;
                          }
                        },
                        icon: Icon(
                          subjects.isEmpty
                              ? Icons.add_rounded
                              : isMarkedToday
                              ? Icons.check_circle_rounded
                              : Icons.pin_drop_rounded,
                          size: 18,
                        ),
                        label: Text(
                          subjects.isEmpty
                              ? '+ Add Subject'
                              : isMarkedToday
                              ? 'Marked Present (Tap to Undo)'
                              : 'Mark Present',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMarkedToday
                              ? const Color(0xFF10B981)
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
          ),
          const SizedBox(height: 14),

          // 3. ATTENDANCE GAUGE CARD (Interactive)
          GestureDetector(
            onTap: () => ref.read(navIndexProvider.notifier).state = 1,
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
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
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
                        painter: _AttendanceGaugePainter(percentage: pct / 100),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${pct.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Text(
                                'Avg',
                                style: TextStyle(
                                  color: Colors.white38,
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
                _showBunkCalculatorSheet(safeBunks, activeSubjectName, target),
            child: GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
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
                        color: Colors.white38,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (stats.totalRecorded == 0)
                    const Text(
                      'No attendance recorded yet. Log attendance to calculate your safe bunk buffer.',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    )
                  else ...[
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
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
                      'in $activeSubjectName to stay above the ${target.toInt()}% threshold.',
                      style: const TextStyle(
                        color: Colors.white60,
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
                              value: (safeBunks / 10.0).clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF7BD0FF),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Buffer',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 5. AI SMART BRIEF CARD (Interactive)
          GestureDetector(
            onTap: () =>
                ref.read(navIndexProvider.notifier).state = 3, // Jump to AI
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131A2B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF5B5FEF).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            children: stats.totalRecorded == 0
                                ? const [
                                    TextSpan(
                                      text:
                                          'Start logging attendance and timetable to receive real-time personalized AI study briefs.',
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
                                          activeSubjectName,
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
              const Text(
                'Remaining Today',
                style: TextStyle(
                  color: Colors.white,
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
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$roomStr$facultyStr',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            entry.startTimeDisplay,
                            style: const TextStyle(
                              color: Colors.white,
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

  _AttendanceGaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
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
    return oldDelegate.percentage != percentage;
  }
}
