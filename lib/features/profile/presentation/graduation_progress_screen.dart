import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/programmes/data/programme_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';
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
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: context.textColor,
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Graduation Progress',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.textColor,
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
                          color: context.mutedTextColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Programme Set',
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set an active programme to view your graduation progress.',
                          style: TextStyle(color: context.subtextColor, fontSize: 13),
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
                              isDark: context.isDark,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(overallProgress * 100).toInt()}%',
                                    style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    'Complete',
                                    style: TextStyle(
                                      color: context.mutedTextColor,
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
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activeProg.degreeType ?? 'Degree'} · Expected ${activeProg.expectedGraduationYear ?? 'TBD'}',
                          style: TextStyle(
                            color: context.mutedTextColor,
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
                              color: context.subtextColor,
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
                  _sectionTitle(context, 'Semester Progress'),
                  const SizedBox(height: 12),
                  _statRow([
                    _statBlock(
                      context,
                      '$completedSems',
                      'Completed',
                      const Color(0xFF10B981),
                    ),
                    _statBlock(
                      context,
                      '$activeSems',
                      'Active',
                      const Color(0xFF5B5FEF),
                    ),
                    _statBlock(context, '$remainingSems', 'Remaining', context.mutedTextColor),
                    _statBlock(context, '$totalSemesters', 'Total', context.subtextColor),
                  ]),
                  const SizedBox(height: 12),
                  _progressBar(
                    context,
                    label: '$completedSems / $totalSemesters semesters',
                    value: totalSemesters > 0
                        ? completedSems / totalSemesters
                        : 0,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 24),

                  // Credits progress
                  _sectionTitle(context, 'Credits Tracker'),
                  const SizedBox(height: 12),
                  _statRow([
                    _statBlock(
                      context,
                      '${completedCredits.toInt()}',
                      'Completed',
                      const Color(0xFF10B981),
                    ),
                    _statBlock(
                      context,
                      '${activeCredits.toInt()}',
                      'In Progress',
                      const Color(0xFF5B5FEF),
                    ),
                    _statBlock(
                      context,
                      '${plannedCredits.toInt()}',
                      'Planned',
                      const Color(0xFF7BD0FF),
                    ),
                    if (targetCredits > 0)
                      _statBlock(
                        context,
                        '${targetCredits.toInt()}',
                        'Target',
                        context.mutedTextColor,
                      ),
                  ]),
                  if (targetCredits > 0) ...[
                    const SizedBox(height: 12),
                    _progressBar(
                      context,
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
                        color: context.mutedTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Subject progress
                  _sectionTitle(context, 'Syllabus Completion'),
                  const SizedBox(height: 12),
                  _statRow([
                    _statBlock(
                      context,
                      '$completedSubs',
                      'Completed',
                      const Color(0xFF10B981),
                    ),
                    _statBlock(
                      context,
                      '$activeSubs',
                      'Active',
                      const Color(0xFF5B5FEF),
                    ),
                    _statBlock(
                      context,
                      '$plannedSubs',
                      'Planned',
                      const Color(0xFFF59E0B),
                    ),
                    _statBlock(context, '$totalSubjects', 'Total', context.mutedTextColor),
                  ]),
                  const SizedBox(height: 12),
                  _progressBar(
                    context,
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
                        Text(
                          'Programme Summary',
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _summaryRow(context, 'Programme', activeProg.name),
                        _summaryRow(
                          context,
                          'Degree',
                          activeProg.degreeType ?? 'Not Set',
                        ),
                        _summaryRow(
                          context,
                          'Joining Year',
                          '${activeProg.joiningYear}',
                        ),
                        _summaryRow(
                          context,
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

  static Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.textColor,
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

  static Widget _statBlock(BuildContext context, String value, String label, Color color) {
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
          style: TextStyle(color: context.mutedTextColor, fontSize: 10),
        ),
      ],
    );
  }

  static Widget _progressBar(
    BuildContext context, {
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
                style: TextStyle(color: context.subtextColor, fontSize: 12),
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
              backgroundColor: context.isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.mutedTextColor, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: context.textColor,
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
  final bool isDark;
  _GraduationRingPainter({required this.progress, required this.isDark});

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
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.03 - i * 0.008)
              : Colors.black.withValues(alpha: 0.03 - i * 0.008)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark ? const Color(0xFF1F2A3C) : const Color(0xFFE2E8F0)
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
  bool shouldRepaint(_GraduationRingPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
