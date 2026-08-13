import 'dart:math' as math;
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
  ConsumerState<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  String _filter = 'all';
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          borderRadius: 20,
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Override Target',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Set a custom attendance target for this subject.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: _overrideController,
                labelText: 'Target (%)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white60,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final val = double.tryParse(_overrideController.text.trim());
                        if (val != null && val >= 1 && val <= 100) {
                          final subjects = ref.read(subjectRepositoryProvider);
                          final sub = subjects.firstWhere((s) => s.id == widget.subjectId);
                          await ref.read(subjectRepositoryProvider.notifier).editSubject(
                            sub.id, sub.name, sub.facultyName, sub.colorValue, val,
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRecord(BuildContext context, dynamic rec) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Delete Record?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('This attendance log will be permanently removed.', style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final backup = rec;
                      await ref.read(attendanceRepositoryProvider.notifier).deleteAttendance(rec.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: const Text('Attendance deleted.'),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () async {
                              await ref.read(attendanceRepositoryProvider.notifier).insertRecord(backup);
                            },
                          ),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _riskColor {
    return 'danger' == 'danger' ? const Color(0xFFEF4444) : const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final subjectStatsList = stats.allSubjectStats.where((s) => s.subject.id == widget.subjectId).toList();

    if (subjectStatsList.isEmpty) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(
            child: Text('Subject not found', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    final subStats = subjectStatsList.first;
    final sub = subStats.subject;
    final records = ref.watch(attendanceRepositoryProvider).where((r) => r.subjectId == sub.id).toList();

    final filteredRecords = records.where((r) {
      if (_filter == 'present') return r.status == 'present';
      if (_filter == 'absent') return r.status == 'absent';
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final subjectColor = Color(sub.colorValue);
    final pct = subStats.percentage;
    final pctColor = pct >= subStats.target ? const Color(0xFF10B981) : pct >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

    final riskLabel = subStats.riskLevel.toUpperCase();
    final riskColor = switch (subStats.riskLevel.toLowerCase()) {
      'safe' => const Color(0xFF10B981),
      'warning' => const Color(0xFFF59E0B),
      _ => const Color(0xFFEF4444),
    };

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => context.pop(),
          ),
          title: Text(sub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.tune_rounded, color: Colors.white.withValues(alpha: 0.6), size: 20),
              onPressed: () => _showOverrideDialog(subStats.target),
              tooltip: 'Override Target',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Hero stat card
            GlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Ring
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: CustomPaint(
                          painter: _AttendanceRingPainter(
                            progress: (pct / 100).clamp(0.0, 1.0),
                            color: pctColor,
                            subjectColor: subjectColor,
                          ),
                          child: Center(
                            child: Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(color: pctColor, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.facultyName.isNotEmpty ? sub.facultyName : 'Instructor Not Set',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(riskLabel, style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _miniStat(subStats.presentCount.toString(), 'Present', const Color(0xFF10B981)),
                                const SizedBox(width: 16),
                                _miniStat(subStats.absentCount.toString(), 'Absent', const Color(0xFFEF4444)),
                                const SizedBox(width: 16),
                                _miniStat('${subStats.totalCount}', 'Total', Colors.white54),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Target: ${subStats.target.toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      if (subStats.safeBunks > 0)
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Can bunk ${subStats.safeBunks} more',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else if (subStats.requiredRecovery > 0)
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Need ${subStats.requiredRecovery} more',
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else
                        const Text('At threshold', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filter + Log header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendance Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Row(
                  children: ['all', 'present', 'absent'].map((f) {
                    final isActive = _filter == f;
                    final fColor = switch (f) {
                      'present' => const Color(0xFF10B981),
                      'absent' => const Color(0xFFEF4444),
                      _ => Colors.white,
                    };
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? fColor.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? fColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(
                            color: isActive ? fColor : Colors.white30,
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
            const SizedBox(height: 12),

            if (filteredRecords.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_outlined, color: Colors.white.withValues(alpha: 0.15), size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _filter == 'all' ? 'No attendance logged yet' : 'No ${_filter} records',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredRecords.map((rec) {
                final isEditable = AttendanceRepository.canEditAttendance(rec, DateTime.now());
                final isPresent = rec.status == 'present';
                final statusColor = isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                final dateStr = '${rec.date.day}/${rec.date.month}/${rec.date.year}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Status dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(
                                rec.periodNumber != null ? 'Period ${rec.periodNumber}' : 'Subject-wise',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rec.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isEditable)
                          GestureDetector(
                            onTap: () => _confirmDeleteRecord(context, rec),
                            child: Icon(Icons.delete_outline_rounded, color: Colors.white.withValues(alpha: 0.25), size: 18),
                          )
                        else
                          Icon(Icons.lock_outline_rounded, color: Colors.white.withValues(alpha: 0.12), size: 15),
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

  static Widget _miniStat(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }
}

class _AttendanceRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color subjectColor;

  _AttendanceRingPainter({required this.progress, required this.color, required this.subjectColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    canvas.drawCircle(center, radius, Paint()
      ..color = const Color(0xFF1F2A3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_AttendanceRingPainter old) => old.progress != progress;
}
