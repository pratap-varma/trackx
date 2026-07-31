import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/programmes/data/programme_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class GraduationProgressScreen extends ConsumerWidget {
  const GraduationProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProg = ref.watch(activeProgrammeProvider);
    final semesters = ref.watch(semesterRepositoryProvider);
    final subjects = ref.watch(subjectRepositoryProvider);

    // Filter by active programme
    final progId = activeProg?.id ?? '';
    final progSemesters = semesters.where((s) => s.programmeId == progId).toList();
    final progSemIds = progSemesters.map((s) => s.id).toSet();
    final progSubjects = subjects.where((s) => progSemIds.contains(s.semesterId)).toList();

    // 1. Semester Progress
    final totalSemesters = activeProg?.totalSemesters ?? 8;
    final completedSemestersCount = progSemesters.where((s) => s.status == 'Completed').length;
    final activeSemestersCount = progSemesters.where((s) => s.status == 'Active').length;
    final remainingSemestersCount = (totalSemesters - completedSemestersCount - activeSemestersCount).clamp(0, totalSemesters);

    // 2. Subject Progress
    final totalSubjects = progSubjects.length;
    final completedSubjectsCount = progSubjects.where((s) => s.status == 'Completed').length;
    final activeSubjectsCount = progSubjects.where((s) => s.status == 'Active').length;
    final plannedSubjectsCount = progSubjects.where((s) => s.status == 'Planned').length;

    // 3. Credit Progress
    final double targetTotalCredits = activeProg?.totalCredits ?? 0.0;
    
    // Sum of credits from completed subjects in active programme
    final double completedCredits = progSubjects
        .where((s) => s.status == 'Completed' && s.credits != null)
        .fold(0.0, (sum, sub) => sum + (sub.credits ?? 0.0));

    final double plannedCredits = progSubjects
        .where((s) => s.status == 'Planned' && s.credits != null)
        .fold(0.0, (sum, sub) => sum + (sub.credits ?? 0.0));

    final double activeCredits = progSubjects
        .where((s) => s.status == 'Active' && s.credits != null)
        .fold(0.0, (sum, sub) => sum + (sub.credits ?? 0.0));

    final double remainingCredits = (targetTotalCredits - completedCredits).clamp(0.0, targetTotalCredits);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Graduation Progress',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: activeProg == null
            ? Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'Please set an active programme first to view graduation progress estimates.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Notice Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3), width: 0.5),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TrackX Estimation Note:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This is a personal planning estimate based on your TrackX data. Confirm official graduation requirements with your college.',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Semester Progress Section
                  const Text('Semester Completion Progress', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 12),
                  GlassContainer(
                    child: Column(
                      children: [
                        _buildProgressBar(
                          label: 'Semesters ($completedSemestersCount / $totalSemesters Completed)',
                          value: totalSemesters > 0 ? (completedSemestersCount / totalSemesters) : 0.0,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStat('Active', '$activeSemestersCount'),
                            _buildMiniStat('Completed', '$completedSemestersCount'),
                            _buildMiniStat('Remaining', '$remainingSemestersCount'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Credit Tracking Section
                  const Text('Credits Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 12),
                  GlassContainer(
                    child: Column(
                      children: [
                        if (targetTotalCredits > 0.0) ...[
                          _buildProgressBar(
                            label: 'Credits ($completedCredits / $targetTotalCredits Completed)',
                            value: completedCredits / targetTotalCredits,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStat('Completed', '$completedCredits'),
                            _buildMiniStat('Active Sem', '$activeCredits'),
                            _buildMiniStat('Planned', '$plannedCredits'),
                            if (targetTotalCredits > 0.0)
                              _buildMiniStat('Remaining', '$remainingCredits'),
                          ],
                        ),
                        if (targetTotalCredits == 0.0) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'No target credits defined for this programme. Set a target in Programme Settings to enable percentage calculations.',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subject Progress Section
                  const Text('Syllabus Completion progress', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 12),
                  GlassContainer(
                    child: Column(
                      children: [
                        _buildProgressBar(
                          label: 'Subjects ($completedSubjectsCount / $totalSubjects Completed)',
                          value: totalSubjects > 0 ? (completedSubjectsCount / totalSubjects) : 0.0,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStat('Active', '$activeSubjectsCount'),
                            _buildMiniStat('Completed', '$completedSubjectsCount'),
                            _buildMiniStat('Planned', '$plannedSubjectsCount'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Overall Info Card
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Programme Summary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Name', activeProg.name),
                        _buildSummaryRow('Degree', activeProg.degreeType ?? 'Not Set'),
                        _buildSummaryRow('Joining Year', '${activeProg.joiningYear}'),
                        _buildSummaryRow('Expected Graduation', '${activeProg.expectedGraduationYear ?? "Not Set"}'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double value,
    required Color color,
  }) {
    final pct = (value * 100).clamp(0, 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
