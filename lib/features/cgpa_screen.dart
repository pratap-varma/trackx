import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class CgpaScreen extends ConsumerStatefulWidget {
  const CgpaScreen({super.key});

  @override
  ConsumerState<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends ConsumerState<CgpaScreen> {
  final _subjectController = TextEditingController();
  final _creditsController = TextEditingController();
  double _gradePoints = 10.0;
  String _gradeLetter = 'O';

  double _simulatedFutureCredits = 15.0;
  double _simulatedFutureGpa = 9.0;

  static const _gradeMap = {
    'O': 10.0,
    'A+': 9.0,
    'A': 8.0,
    'B+': 7.0,
    'B': 6.0,
    'C': 5.0,
    'F': 0.0,
  };

  @override
  void dispose() {
    _subjectController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Color _gradeColor(String grade) {
    return switch (grade) {
      'O' || 'A+' => const Color(0xFF10B981),
      'A' || 'B+' => const Color(0xFF7BD0FF),
      'B' || 'C' => const Color(0xFFF59E0B),
      _ => const Color(0xFFEF4444),
    };
  }

  void _showAddCourseSheet(String activeSemId) {
    _subjectController.clear();
    _creditsController.clear();
    _gradePoints = 10.0;
    _gradeLetter = 'O';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String localGrade = _gradeLetter;
        final sheetBg = ctx.isDark ? const Color(0xFF0E1628) : Colors.white;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: ctx.mutedTextColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Record Subject Grade',
                    style: TextStyle(
                      color: ctx.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassTextField(
                    controller: _subjectController,
                    labelText: 'Subject Name',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _creditsController,
                    labelText: 'Credits',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Grade picker chips
                  const Text(
                    'Select Grade',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _gradeMap.entries.map((e) {
                      final isSelected = localGrade == e.key;
                      final color = _gradeColor(e.key);
                      return GestureDetector(
                        onTap: () => setSheet(() {
                          localGrade = e.key;
                          _gradeLetter = e.key;
                          _gradePoints = e.value;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? color.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.06),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                e.key,
                                style: TextStyle(
                                  color: isSelected ? color : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${e.value.toInt()}',
                                style: TextStyle(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.7)
                                      : Colors.white24,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        final credits =
                            int.tryParse(_creditsController.text.trim()) ?? 0;
                        if (_subjectController.text.trim().isEmpty ||
                            credits <= 0) {
                          return;
                        }
                        ref
                            .read(courseGradesProvider.notifier)
                            .addGrade(
                              CourseGrade(
                                id: 'grade-${DateTime.now().millisecondsSinceEpoch}',
                                semesterId: activeSemId,
                                subjectName: _subjectController.text.trim(),
                                credits: credits,
                                grade: _gradeLetter,
                                gradePoints: _gradePoints,
                              ),
                            );
                        Navigator.pop(ctx);
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
                            'Save Grade',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = ref.watch(activeSemesterProvider);
    final grades = ref.watch(courseGradesProvider);
    final gpaSummary = ref.watch(cgpaCalculatorProvider);

    if (activeSem == null) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grade_outlined, color: context.mutedTextColor, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Semester',
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please activate a semester in Profile settings first.',
                      style: TextStyle(color: context.subtextColor, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final activeGrades = grades
        .where((g) => g.semesterId == activeSem.id)
        .toList();

    double totalCredits = 0;
    double totalWeightedPoints = 0;
    for (final g in activeGrades) {
      totalCredits += g.credits;
      totalWeightedPoints += g.gradePoints * g.credits;
    }

    final simulatedCgpa = (totalCredits + _simulatedFutureCredits) == 0
        ? 0.0
        : (totalWeightedPoints +
                  (_simulatedFutureGpa * _simulatedFutureCredits)) /
              (totalCredits + _simulatedFutureCredits);

    final cgpa = gpaSummary['cgpa']!;
    final sgpa = gpaSummary['sgpa']!;
    final cgpaColor = cgpa >= 9.0
        ? const Color(0xFF10B981)
        : cgpa >= 7.0
        ? const Color(0xFF7BD0FF)
        : const Color(0xFFF59E0B);

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
            'CGPA Tracker',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.textColor,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _showAddCourseSheet(activeSem.id),
                child: GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(8),
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
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Hero CGPA ring
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _CgpaRingPainter(
                    cgpa: cgpa,
                    color: cgpaColor,
                    isDark: context.isDark,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cgpa.toStringAsFixed(2),
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'CGPA',
                          style: TextStyle(
                            color: context.mutedTextColor,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          sgpa.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Color(0xFF7BD0FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          'Sem SGPA',
                          style: TextStyle(color: context.mutedTextColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          '${activeGrades.length}',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          'Subjects',
                          style: TextStyle(color: context.mutedTextColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          totalCredits.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          'Credits',
                          style: TextStyle(color: context.mutedTextColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // What-If Simulator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What-If Simulator',
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Forecast CGPA with future credits',
                        style: TextStyle(color: context.mutedTextColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8151EB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8151EB).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    simulatedCgpa.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Color(0xFFC0C1FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Future Credits',
                        style: TextStyle(color: context.subtextColor, fontSize: 12),
                      ),
                      Text(
                        '${_simulatedFutureCredits.toInt()}',
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF5B5FEF),
                      inactiveTrackColor: context.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                      thumbColor: context.isDark ? Colors.white : AppTheme.accentPurple,
                      overlayColor: const Color(
                        0xFF5B5FEF,
                      ).withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _simulatedFutureCredits,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      onChanged: (v) =>
                          setState(() => _simulatedFutureCredits = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expected GPA',
                        style: TextStyle(color: context.subtextColor, fontSize: 12),
                      ),
                      Text(
                        _simulatedFutureGpa.toStringAsFixed(1),
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF8151EB),
                      inactiveTrackColor: context.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                      thumbColor: context.isDark ? Colors.white : AppTheme.accentPurple,
                      overlayColor: const Color(
                        0xFF8151EB,
                      ).withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _simulatedFutureGpa,
                      min: 0,
                      max: 10,
                      divisions: 100,
                      onChanged: (v) => setState(() => _simulatedFutureGpa = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Grades list
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Subject Grades',
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '${activeGrades.length} recorded',
                  style: TextStyle(
                    color: context.mutedTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (activeGrades.isEmpty)
              GlassContainer(
                borderRadius: 18,
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      Icons.grade_outlined,
                      color: context.mutedTextColor,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No grades yet',
                      style: TextStyle(color: context.subtextColor, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to add your first subject grade.',
                      style: TextStyle(color: context.mutedTextColor, fontSize: 11),
                    ),
                  ],
                ),
              )
            else
              ...activeGrades.map((g) {
                final color = _gradeColor(g.grade);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              g.grade,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.subjectName,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${g.credits} credits · ${g.gradePoints.toInt()} pts',
                                style: TextStyle(
                                  color: context.mutedTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref
                              .read(courseGradesProvider.notifier)
                              .deleteGrade(g.id),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CgpaRingPainter extends CustomPainter {
  final double cgpa;
  final Color color;
  final bool isDark;
  _CgpaRingPainter({required this.cgpa, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 18) / 2;
    final progress = (cgpa / 10.0).clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark ? const Color(0xFF1F2A3C) : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [color, color.withValues(alpha: 0.6)],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_CgpaRingPainter old) =>
      old.cgpa != cgpa || old.color != color || old.isDark != isDark;
}
