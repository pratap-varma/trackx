import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/attendance/presentation/widgets/attendance_heatmap_widget.dart';
import 'package:trackx/features/attendance/providers/attendance_heatmap_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class AttendanceHeatmapScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;

  const AttendanceHeatmapScreen({super.key, this.initialSubjectId});

  @override
  ConsumerState<AttendanceHeatmapScreen> createState() =>
      _AttendanceHeatmapScreenState();
}

class _AttendanceHeatmapScreenState
    extends ConsumerState<AttendanceHeatmapScreen> {
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectRepositoryProvider);
    final dataset = ref.watch(attendanceHeatmapProvider(_selectedSubjectId));

    final selectedSubjectName = _selectedSubjectId == null
        ? 'All Subjects'
        : subjects
            .where((s) => s.id == _selectedSubjectId)
            .firstOrNull
            ?.name ??
            'Selected Subject';

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Attendance Heatmap',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Subject Filter Bar
            if (subjects.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All Subjects'),
                      selected: _selectedSubjectId == null,
                      selectedColor: const Color(0xFF5B5FEF),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: _selectedSubjectId == null
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedSubjectId = null);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ...subjects.map((sub) {
                      final isSelected = _selectedSubjectId == sub.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(sub.name),
                          selected: isSelected,
                          selectedColor: const Color(0xFF5B5FEF),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.05),
                          labelStyle: TextStyle(
                            color:
                                isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSubjectId = sub.id);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Top KPI Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'STREAK',
                    value: '${dataset.currentStreak}d',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'BEST STREAK',
                    value: '${dataset.longestStreak}d',
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'OVERALL',
                    value: '${dataset.overallPercentage.toInt()}%',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFF7BD0FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Main Interactive Heatmap Calendar Widget
            if (dataset.totalDaysLogged == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: GlassContainer(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(32),
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No Attendance Records for $selectedSubjectName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mark attendance from the Attendance screen or timetable to see your activity grid.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              AttendanceHeatmapWidget(dataset: dataset),

            const SizedBox(height: 20),

            // Attendance Summary Stats Card
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              borderColor: Colors.white.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedSubjectName Breakdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    label: 'Classes Attended',
                    value: '${dataset.totalClassesAttended}',
                    color: const Color(0xFF10B981),
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatRow(
                    label: 'Classes Missed',
                    value: '${dataset.totalClassesMissed}',
                    color: const Color(0xFFEF4444),
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatRow(
                    label: 'Total Active Days Logged',
                    value: '${dataset.totalDaysLogged} days',
                    color: const Color(0xFF7BD0FF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderColor: color.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
