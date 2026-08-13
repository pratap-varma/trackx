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
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _showAiScoreSheet(int score, String rating) {
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
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Readiness Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('$rating • Top 5% of Class', style: const TextStyle(color: Color(0xFF7BD0FF), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Text('$score', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            _scoreBar('Attendance Consistency', 0.92, const Color(0xFF10B981)),
            const SizedBox(height: 12),
            _scoreBar('Study Rhythm & Focus', 0.88, const Color(0xFF5B5FEF)),
            const SizedBox(height: 12),
            _scoreBar('Exam Readiness Index', 0.85, const Color(0xFF7BD0FF)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(navIndexProvider.notifier).state = 3; // Jump to AI Assistant
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Get AI Recommendations', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBunkCalculatorSheet(int safeBunks, String subjectName, double target) {
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B243B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: Color(0xFF7BD0FF), size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Safe-to-Bunk Calculator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Target Threshold: ${target.toInt()}%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131A2B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7BD0FF).withValues(alpha: 0.3)),
              ),
              child: Text(
                'You can safely skip $safeBunks class(es) in $subjectName without falling below your ${target.toInt()}% attendance target.',
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(navIndexProvider.notifier).state = 1; // Jump to Attendance
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('View All Subject Buffers', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('${(val * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
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
    final name = profile?.name.isNotEmpty == true ? profile!.name.split(' ').first : 'Alex';

    final activeSem = ref.watch(activeSemesterProvider);
    final stats = ref.watch(statsProvider);
    final subjects = ref.watch(subjectRepositoryProvider);
    final timetableEntries = ref.watch(timetableRepositoryProvider);

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final pct = stats.overallPercentage;
    final target = stats.globalTarget;
    final safeBunks = max(0, ((stats.totalPresent - (target / 100.0 * stats.totalRecorded)) / 1.0).floor());

    const aiScore = 92;
    const aiScoreRating = 'Excellent';

    TimetableEntry? currentClass;
    if (timetableEntries.isNotEmpty) {
      currentClass = timetableEntries.first;
    }

    final activeSubjectName = currentClass != null
        ? subjects.where((s) => s.id == currentClass!.subjectId).firstOrNull?.name ?? 'Advanced Neural Networks'
        : subjects.firstOrNull?.name ?? 'Advanced Neural Networks';

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
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC0C1FF), size: 22),
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
            onTap: () => _showAiScoreSheet(aiScore, aiScoreRating),
            child: GlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Color(0xFFC0C1FF), size: 14),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$aiScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white38),
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
                    const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        currentClass != null
                            ? '${currentClass.room ?? "Science Building, Room 304"} • ${currentClass.startTimeDisplay} - ${currentClass.endTimeDisplay}'
                            : 'Science Building, Room 304 • 10:00 AM - 11:30 AM',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (activeSem != null && subjects.isNotEmpty) {
                        final subId = currentClass?.subjectId ?? subjects.first.id;
                        ref.read(attendanceRepositoryProvider.notifier).markAttendance(
                              userId: profile?.id ?? 'u1',
                              semesterId: activeSem.id,
                              subjectId: subId,
                              date: DateTime.now(),
                              status: 'present',
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attendance Marked as Present for Current Class!')),
                        );
                      } else {
                        ref.read(navIndexProvider.notifier).state = 1;
                      }
                    },
                    icon: const Icon(Icons.pin_drop_rounded, size: 18),
                    label: const Text(
                      'Mark Present',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B5FEF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
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
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => ref.read(navIndexProvider.notifier).state = 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: _AttendanceGaugePainter(
                          percentage: pct / 100,
                        ),
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
                                style: TextStyle(color: Colors.white38, fontSize: 11),
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
            onTap: () => _showBunkCalculatorSheet(safeBunks, activeSubjectName, target),
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
                          Icon(Icons.verified_user_outlined, color: Color(0xFF7BD0FF), size: 16),
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
                      Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
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
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.65,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF7BD0FF)),
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
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 5. AI SMART BRIEF CARD (Interactive)
          GestureDetector(
            onTap: () => ref.read(navIndexProvider.notifier).state = 3, // Jump to AI
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
                    child: const Icon(Icons.insights_rounded, color: Color(0xFFC0C1FF), size: 20),
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
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            children: [
                              const TextSpan(text: 'Based on your recent quiz scores, dedicating 30 minutes to review '),
                              TextSpan(
                                text: activeSubjectName,
                                style: const TextStyle(color: Color(0xFFD0BCFF), fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' before tomorrow\'s class will optimize your performance trend.'),
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

          // Remaining Class 1
          GestureDetector(
            onTap: () => ref.read(navIndexProvider.notifier).state = 1,
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0C1FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Quantum Mechanics & Optics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hall 4 • Dr. Aris Thorne',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '01:00 PM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Remaining Class 2
          GestureDetector(
            onTap: () => ref.read(navIndexProvider.notifier).state = 1,
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8151EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Data Structures & Algorithms',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Lab 2 • Prof. Higgins',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '03:30 PM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
