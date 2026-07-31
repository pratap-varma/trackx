import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  String _filter = 'all'; // 'all', 'present', 'absent'
  final _overrideController = TextEditingController();

  @override
  void dispose() {
    _overrideController.dispose();
    super.dispose();
  }

  void _showOverrideDialog(double currentTarget) {
    _overrideController.text = currentTarget.toInt().toString();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Target Override',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: _overrideController,
                  labelText: 'Override Target (%)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final val = double.tryParse(
                          _overrideController.text.trim(),
                        );
                        if (val != null && val >= 1 && val <= 100) {
                          final subjects = ref.read(subjectRepositoryProvider);
                          final sub = subjects.firstWhere(
                            (s) => s.id == widget.subjectId,
                          );
                          await ref
                              .read(subjectRepositoryProvider.notifier)
                              .editSubject(
                                sub.id,
                                sub.name,
                                sub.facultyName,
                                sub.colorValue,
                                val,
                              );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final subjectStatsList = stats.allSubjectStats
        .where((s) => s.subject.id == widget.subjectId)
        .toList();

    if (subjectStatsList.isEmpty) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: const BackButton(color: Colors.white),
          ),
          body: const Center(
            child: Text(
              'Subject not found',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final subStats = subjectStatsList.first;
    final sub = subStats.subject;
    final records = ref
        .watch(attendanceRepositoryProvider)
        .where((r) => r.subjectId == sub.id)
        .toList();

    // Apply Filter
    final filteredRecords = records.where((r) {
      if (_filter == 'present') return r.status == 'present';
      if (_filter == 'absent') return r.status == 'absent';
      return true;
    }).toList();

    // Sort Chronologically descending
    filteredRecords.sort((a, b) => b.date.compareTo(a.date));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            sub.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_road, color: Colors.white),
              onPressed: () => _showOverrideDialog(subStats.target),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Details summary card
            GlassContainer(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructor',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            sub.facultyName.isNotEmpty
                                ? sub.facultyName
                                : 'Not Assigned',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          subStats.riskLevel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniMetric(
                        'Attendance',
                        '${subStats.percentage.toStringAsFixed(1)}%',
                      ),
                      _buildMiniMetric('Target', '${subStats.target.toInt()}%'),
                      _buildMiniMetric(
                        'Classes',
                        '${subStats.presentCount}/${subStats.totalCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (subStats.safeBunks > 0)
                    Text(
                      'You can safely bunk next ${subStats.safeBunks} classes.',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (subStats.requiredRecovery > 0)
                    Text(
                      'Attend next ${subStats.requiredRecovery} classes to reach target.',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const Text(
                      'At minimum target threshold.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Log Filter header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Log',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: ['all', 'present', 'absent'].map((f) {
                    final isActive = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white10 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? Colors.white24
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          f.toUpperCase(),
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // History ListView
            if (filteredRecords.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No attendance records logged.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              ...filteredRecords.map((rec) {
                final isEditable = AttendanceRepository.canEditAttendance(
                  rec,
                  DateTime.now(),
                );
                final dateStr =
                    '${rec.date.day}/${rec.date.month}/${rec.date.year}';
                final isPresent = rec.status == 'present';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              rec.periodNumber != null
                                  ? 'Period ${rec.periodNumber}'
                                  : 'Subject-wise Daily',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                rec.status.toUpperCase(),
                                style: TextStyle(
                                  color: isPresent
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isEditable)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white60,
                                  size: 18,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor: Colors.transparent,
                                        content: GlassContainer(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Confirm Delete',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Do you want to delete this log entry?',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: Colors.white60,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.redAccent,
                                                        ),
                                                    onPressed: () async {
                                                      // Save backup for undo before deletion
                                                      final backup = rec;
                                                      await ref
                                                          .read(
                                                            attendanceRepositoryProvider
                                                                .notifier,
                                                          )
                                                          .deleteAttendance(
                                                            rec.id,
                                                          );
                                                      if (context.mounted) {
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: const Text(
                                                              'Attendance log deleted.',
                                                            ),
                                                            action: SnackBarAction(
                                                              label: 'UNDO',
                                                              onPressed: () async {
                                                                await ref
                                                                    .read(
                                                                      attendanceRepositoryProvider
                                                                          .notifier,
                                                                    )
                                                                    .insertRecord(
                                                                      backup,
                                                                    );
                                                              },
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                            else
                              const Icon(
                                Icons.lock,
                                color: Colors.white30,
                                size: 16,
                              ),
                          ],
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

  Widget _buildMiniMetric(String title, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }
}
