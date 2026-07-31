import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/timetable/providers/timetable_provider.dart';
import 'package:trackx/routing/nav_provider.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authRepositoryProvider);
    final profile = authState.userProfile;
    final name = profile?.name ?? 'Student';

    final activeSem = ref.watch(activeSemesterProvider);
    final stats = ref.watch(statsProvider);
    final subjects = ref.watch(subjectRepositoryProvider);

    // Live Timetable data
    final currentClass = ref.watch(currentClassProvider);
    final nextClass = ref.watch(nextClassProvider);
    final unmarkedList = ref.watch(completedUnmarkedClassesProvider);

    // Productivity metrics
    final activeTasks = ref
        .watch(tasksProvider)
        .where((t) => !t.isCompleted)
        .toList();
    final cgpaSummary = ref.watch(cgpaCalculatorProvider);
    final smartSuggestions = ref.watch(smartSuggestionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Profile row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeSem != null
                        ? 'Active: ${activeSem.name}'
                        : 'No Active Semester',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          if (activeSem == null)
            GlassContainer(
              width: double.infinity,
              child: Column(
                children: [
                  const Text(
                    'No Active Semester',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Setup a semester inside profile settings to enable attendance logs.',
                    style: TextStyle(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(navIndexProvider.notifier).state =
                        4, // Profile tab
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
            )
          else ...[
            // Glass Hero Card
            GlassContainer(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Attendance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: stats.overallPercentage >= stats.globalTarget
                              ? AppTheme.accentGreen.withOpacity(0.15)
                              : AppTheme.accentPink.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: stats.overallPercentage >= stats.globalTarget
                                ? AppTheme.accentGreen.withOpacity(0.3)
                                : AppTheme.accentPink.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          stats.overallPercentage >= stats.globalTarget
                              ? 'ON TRACK'
                              : 'BELOW TARGET',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: stats.overallPercentage >= stats.globalTarget
                                ? AppTheme.accentGreen
                                : AppTheme.accentPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${stats.overallPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Goal: ${stats.globalTarget.toInt()}% • ${stats.totalPresent}/${stats.totalRecorded} classes',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: stats.totalRecorded == 0
                                  ? 0.0
                                  : stats.totalPresent / stats.totalRecorded,
                              strokeWidth: 8,
                              backgroundColor: Colors.white10,
                              color: AppTheme.accentPurple,
                            ),
                          ),
                          Text(
                            '${stats.overallPercentage.toInt()}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Timetable Card
            if (currentClass != null) ...[
              GlassContainer(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Now Happening',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subjects
                          .firstWhere((s) => s.id == currentClass.subjectId)
                          .name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${currentClass.startTimeDisplay} - ${currentClass.endTimeDisplay}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (nextClass != null) ...[
              GlassContainer(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Up Next',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subjects
                          .firstWhere((s) => s.id == nextClass.subjectId)
                          .name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${nextClass.startTimeDisplay} - ${nextClass.endTimeDisplay}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (unmarkedList.isNotEmpty) ...[
              GlassContainer(
                width: double.infinity,
                child: Row(
                  children: [
                    const Icon(
                      Icons.mark_chat_unread_outlined,
                      color: Colors.amberAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${unmarkedList.length} Attendance Reminders',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Some classes completed today need logging.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Highlights
            if (stats.highestRiskSubjectName != null) ...[
              GlassContainer(
                width: double.infinity,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.accentPink,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'At Risk Subject',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${stats.highestRiskSubjectName} requires consecutive attendances to recover.',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Smart offline insights
            if (smartSuggestions.isNotEmpty) ...[
              GlassContainer(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart Insights',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...smartSuggestions.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          '• $s',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Active Tasks overview
            if (activeTasks.isNotEmpty) ...[
              GlassContainer(
                width: double.infinity,
                child: Row(
                  children: [
                    const Icon(
                      Icons.playlist_add_check,
                      color: Colors.greenAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${activeTasks.length} Pending Tasks',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Keep up with your upcoming priorities.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // CGPA Display
            if (cgpaSummary['cgpa']! > 0.0) ...[
              GlassContainer(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cumulative CGPA',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Calculated based on logged course grades.',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      cgpaSummary['cgpa']!.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Quick actions
            GlassContainer(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Logging',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Update logs for active classes',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(navIndexProvider.notifier).state =
                        1, // Attendance tab
                    child: const Text('Mark Present / Absent'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
