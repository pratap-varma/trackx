import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/programmes/data/programme_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'dart:math' as math;

class GraduationProgressScreen extends ConsumerWidget {
  const GraduationProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProg = ref.watch(activeProgrammeProvider);
    final semesters = ref.watch(semesterRepositoryProvider);
    final subjects = ref.watch(subjectRepositoryProvider);

    final progId = activeProg?.id ?? '';
    final progSemesters = semesters
        .where((s) => s.programmeId == progId)
        .toList();
    final progSemIds = progSemesters.map((s) => s.id).toSet();
    final progSubjects = subjects
        .where((s) => progSemIds.contains(s.semesterId))
        .toList();

    final totalSemesters = activeProg?.totalSemesters ?? 8;
    final completedSems = progSemesters
        .where((s) => s.status == 'Completed')
        .length;
    final activeSems = progSemesters.where((s) => s.status == 'Active').length;
    final remainingSems = (totalSemesters - completedSems - activeSems).clamp(
      0,
      totalSemesters,
    );

    final totalSubjects = progSubjects.length;
    final completedSubs = progSubjects
        .where((s) => s.status == 'Completed')
        .length;
    final activeSubs = progSubjects.where((s) => s.status == 'Active').length;
    final plannedSubs = progSubjects.where((s) => s.status == 'Planned').length;

    final double targetCredits = activeProg?.totalCredits ?? 0.0;
    final double completedCredits = progSubjects
        .where((s) => s.status == 'Completed' && s.credits != null)
        .fold(0.0, (sum, s) => sum + (s.credits ?? 0.0));
    final double activeCredits = progSubjects
        .where((s) => s.status == 'Active' && s.credits != null)
        .fold(0.0, (sum, s) => sum + (s.credits ?? 0.0));
    final double plannedCredits = progSubjects
        .where((s) => s.status == 'Planned' && s.credits != null)
        .fold(0.0, (sum, s) => sum + (s.credits ?? 0.0));

    final overallProgress = totalSemesters > 0
        ? completedSems / totalSemesters
        : 0.0;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Graduation Progress',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: activeProg == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: GlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Programme Set',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Set an active programme to view your graduation progress.',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  // Hero graduation orb
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CustomPaint(
                            painter: _GraduationRingPainter(
                              progress: overallProgress,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(overallProgress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const Text(
                                    'Complete',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeProg.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activeProg.degreeType ?? 'Degree'} · Expected ${activeProg.expectedGraduationYear ?? 'TBD'}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Estimation note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FEF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFC0C1FF),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is a personal planning estimate based on your TrackX data. Always confirm with your college for official requirements.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Semester progress
                  _sectionTitle('Semester Progress'),
                  const SizedBox(height: 12),
                  _statRow([
                    _statBlock(
                      '$completedSems',
                      'Completed',
                      const Color(0xFF10B981),
                    ),
                    _statBlock(
                      '$activeSems',
                      'Active',
                      const Color(0xFF5B5FEF),
                    ),
                    _statBlock('$remainingSems', 'Remaining', Colors.white38),
                    _statBlock('$totalSemesters', 'Total', Colors.white54),
                  ]),
                  const SizedBox(height: 12),
                  _progressBar(
                    label: '$completedSems / $totalSemesters semesters',
                    value: totalSemesters > 0
                        ? completedSems / totalSemesters
                        : 0,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 24),

                  // Credits progress
                  _sectionTitle('Credits Tracker'),
                  const SizedBox(height: 12),
                  _statRow([
                    _statBlock(
                      '${completedCredits.toInt()}',
                      'Completed',
                      const Color(0xFF10B981),
                    ),
                    _statBlock(
                      '${activeCredits.toInt()}',
                      'In Progress',
                      const Color(0xFF5B5FEF),
                    ),
                    _statBlock(
                      '${plannedCredits.toInt()}',
                      'Planned',
                      const Color(0xFF7BD0FF),
                    ),
                    if (targetCredits > 0)
                      _statBlock(
                        '${targetCredits.toInt()}',
                        'Target',
                        Colors.white38,
                      ),
                  ]),
                  if (targetCredits > 0) ...[
                    const SizedBox(height: 12),
                    _progressBar(
                      label:
                          '${completedCredits.toInt()} / ${targetCredits.toInt()} credits',
                      value: completedCredits / targetCredits,
                      color: const Color(0xFF7BD0FF),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Set a target in Programme Settings to enable credit calculations.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Subject progress
                  _sectionTitle('Syllabus Completion'),
                  const SizedBox(height: 12),
                  _statRow([
                    _statBlock(
                      '$completedSubs',
                      'Completed',
                      const Color(0xFF10B981),
                    ),
                    _statBlock(
                      '$activeSubs',
                      'Active',
                      const Color(0xFF5B5FEF),
                    ),
                    _statBlock(
                      '$plannedSubs',
                      'Planned',
                      const Color(0xFFF59E0B),
                    ),
                    _statBlock('$totalSubjects', 'Total', Colors.white38),
                  ]),
                  const SizedBox(height: 12),
                  _progressBar(
                    label: '$completedSubs / $totalSubjects subjects',
                    value: totalSubjects > 0
                        ? completedSubs / totalSubjects
                        : 0,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 24),

                  // Programme summary
                  GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Programme Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _summaryRow('Programme', activeProg.name),
                        _summaryRow(
                          'Degree',
                          activeProg.degreeType ?? 'Not Set',
                        ),
                        _summaryRow(
                          'Joining Year',
                          '${activeProg.joiningYear}',
                        ),
                        _summaryRow(
                          'Expected Graduation',
                          '${activeProg.expectedGraduationYear ?? 'Not Set'}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  static Widget _statRow(List<Widget> items) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items,
      ),
    );
  }

  static Widget _statBlock(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  static Widget _progressBar({
    required String label,
    required double value,
    required Color color,
  }) {
    final pct = (value * 100).clamp(0.0, 100.0).toInt();
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraduationRingPainter extends CustomPainter {
  final double progress;
  _GraduationRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Background rings
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        center,
        radius - i * 14,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.03 - i * 0.008)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1F2A3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    // Progress
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [Color(0xFF5B5FEF), Color(0xFF10B981), Color(0xFF7BD0FF)],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GraduationRingPainter old) => old.progress != progress;
}
