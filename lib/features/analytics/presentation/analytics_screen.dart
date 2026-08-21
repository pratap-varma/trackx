import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  // Forecaster Slider variables
  double _futurePresent = 5.0;
  double _futureAbsent = 0.0;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final subjects = ref.watch(subjectRepositoryProvider);

    // What-If Calculator simulation logic
    final totalRec = stats.totalRecorded;
    final totalPres = stats.totalPresent;
    final simTotal = totalRec + _futurePresent.toInt() + _futureAbsent.toInt();
    final simPresent = totalPres + _futurePresent.toInt();
    final simPercentage = simTotal == 0 ? 0.0 : (simPresent / simTotal) * 100.0;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Analytics & Intelligence',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Overall Stats Donut Row
            GlassContainer(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Presence Ratio',
                          style: TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.overallPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${stats.totalPresent} present / ${stats.totalRecorded} classes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: stats.totalRecorded == 0
                          ? 0.0
                          : stats.totalPresent / stats.totalRecorded,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attendance Forecast Simulator
            const Text(
              'What-If Forecast Simulator',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulated Target: ${simPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: simPercentage >= stats.globalTarget
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Attend next ${_futurePresent.toInt()} classes',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Slider(
                    value: _futurePresent,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    activeColor: AppTheme.accentPurple,
                    onChanged: (val) => setState(() => _futurePresent = val),
                  ),
                  Text(
                    'Miss next ${_futureAbsent.toInt()} classes',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Slider(
                    value: _futureAbsent,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    activeColor: AppTheme.accentPurple,
                    onChanged: (val) => setState(() => _futureAbsent = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Subject Comparison
            const Text(
              'Subject Comparisons',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (subjects.isEmpty)
              const GlassContainer(
                child: Center(
                  child: Text(
                    'No subjects added yet.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              )
            else
              ...subjects.map((sub) {
                final subStats = stats.allSubjectStats
                    .where((s) => s.subject.id == sub.id)
                    .firstOrNull;
                final percent = subStats?.percentage ?? 0.0;
                final target = sub.targetOverride ?? stats.globalTarget;
                final isAtRisk = percent < target;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sub.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${percent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAtRisk
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percent / 100.0,
                          backgroundColor: Colors.white10,
                          color: isAtRisk
                              ? Colors.redAccent
                              : AppTheme.accentPurple,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ${target.toInt()}% ${isAtRisk ? "(At Risk)" : "(On Track)"}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
