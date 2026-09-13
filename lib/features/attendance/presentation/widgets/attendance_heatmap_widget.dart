import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/attendance/domain/models/attendance_heatmap_models.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AttendanceHeatmapWidget extends StatefulWidget {
  final HeatmapDataset dataset;
  final ScrollController? scrollController;
  final ValueChanged<DayAttendanceSummary>? onDaySelected;

  const AttendanceHeatmapWidget({
    super.key,
    required this.dataset,
    this.scrollController,
    this.onDaySelected,
  });

  @override
  State<AttendanceHeatmapWidget> createState() =>
      _AttendanceHeatmapWidgetState();
}

class _AttendanceHeatmapWidgetState extends State<AttendanceHeatmapWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();

    // Auto-scroll to today after render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysFromStart = today.difference(widget.dataset.startDate).inDays;
    if (daysFromStart > 0) {
      final weekIndex = (daysFromStart / 7).floor();
      final targetOffset = (weekIndex * 20.0) - 100;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showDayBreakdown(
    BuildContext context,
    DayAttendanceSummary summary,
  ) {
    HapticFeedback.lightImpact();
    if (widget.onDaySelected != null) {
      widget.onDaySelected!(summary);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DayAttendanceBreakdownSheet(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final mutedTextColor = context.mutedTextColor;

    final totalDays =
        widget.dataset.endDate.difference(widget.dataset.startDate).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    final List<Widget> monthHeaders = [];
    int lastMonth = -1;

    for (int w = 0; w < totalWeeks; w++) {
      final weekDate =
          widget.dataset.startDate.add(Duration(days: w * 7));
      if (weekDate.month != lastMonth) {
        lastMonth = weekDate.month;
        monthHeaders.add(
          Container(
            width: 20.0,
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('MMM').format(weekDate),
              style: TextStyle(
                color: mutedTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else {
        monthHeaders.add(const SizedBox(width: 20.0));
      }
    }

    return GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Jump to Today Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_view_month_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ATTENDANCE ACTIVITY',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _scrollToToday,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5FEF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF5B5FEF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded,
                          size: 11, color: Color(0xFF5B5FEF)),
                      SizedBox(width: 4),
                      Text(
                        'Today',
                        style: TextStyle(
                          color: Color(0xFF5B5FEF),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Heatmap Matrix
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekday labels on left (Mon, Wed, Fri)
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _weekdayLabel('S', mutedTextColor),
                    _weekdayLabel('M', mutedTextColor),
                    _weekdayLabel('T', mutedTextColor),
                    _weekdayLabel('W', mutedTextColor),
                    _weekdayLabel('T', mutedTextColor),
                    _weekdayLabel('F', mutedTextColor),
                    _weekdayLabel('S', mutedTextColor),
                  ],
                ),
              ),

              // Scrollable Grid of Week Columns
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month labels on top
                      Row(children: monthHeaders),
                      const SizedBox(height: 6),

                      // 7 Day Rows
                      for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              for (int w = 0; w < totalWeeks; w++)
                                Builder(
                                  builder: (context) {
                                    final date = widget.dataset.startDate
                                        .add(Duration(days: w * 7 + dayOfWeek));
                                    final summary =
                                        widget.dataset.daySummaries[date] ??
                                            DayAttendanceSummary.fromRecords(
                                                date, []);
                                    final isToday = date.year == today.year &&
                                        date.month == today.month &&
                                        date.day == today.day;
                                    final isFuture = date.isAfter(today);

                                    return GestureDetector(
                                      onTap: () =>
                                          _showDayBreakdown(context, summary),
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: isFuture
                                              ? (isDark
                                                  ? Colors.white.withValues(alpha: 0.02)
                                                  : Colors.black.withValues(alpha: 0.02))
                                              : (summary.status == DayAttendanceStatus.noClasses
                                                  ? (isDark
                                                      ? Colors.white.withValues(alpha: 0.05)
                                                      : Colors.black.withValues(alpha: 0.05))
                                                  : summary.statusColor),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isToday
                                                ? const Color(0xFF5B5FEF)
                                                : (summary.totalClasses > 0
                                                    ? (isDark
                                                        ? Colors.white.withValues(alpha: 0.15)
                                                        : Colors.black.withValues(alpha: 0.1))
                                                    : Colors.transparent),
                                            width: isToday ? 1.5 : 0.5,
                                          ),
                                          boxShadow: summary.status ==
                                                  DayAttendanceStatus.fullPresent
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF10B981)
                                                            .withValues(
                                                                alpha: 0.3),
                                                    blurRadius: 4,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.dataset.totalDaysLogged} active days logged',
                style: TextStyle(color: mutedTextColor, fontSize: 11),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendItem(const Color(0xFF10B981), '100%', subtextColor),
                  const SizedBox(width: 8),
                  _legendItem(const Color(0xFF3B82F6), 'Partial', subtextColor),
                  const SizedBox(width: 8),
                  _legendItem(const Color(0xFFEF4444), 'Missed', subtextColor),
                  const SizedBox(width: 8),
                  _legendItem(const Color(0xFF8151EB), 'Off/Event', subtextColor),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weekdayLabel(String label, Color color) {
    return Container(
      height: 20,
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: 10),
        ),
      ],
    );
  }
}

class _DayAttendanceBreakdownSheet extends ConsumerWidget {
  final DayAttendanceSummary summary;

  const _DayAttendanceBreakdownSheet({required this.summary});

  void _confirmDeleteDayRecord(
    BuildContext context,
    WidgetRef ref,
    AttendanceRecord rec,
    String subjectName,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final dateFormatted = DateFormat('EEE, MMM d, yyyy').format(rec.date);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Delete Attendance Record?',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Permanently delete the ${rec.status.toUpperCase()} record for $subjectName on $dateFormatted${rec.periodNumber != null ? ' (Period ${rec.periodNumber})' : ''}?',
              style: TextStyle(color: subtextColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: subtextColor,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final backup = rec;
                      await ref
                          .read(attendanceRepositoryProvider.notifier)
                          .deleteAttendance(rec.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Attendance for $subjectName deleted.'),
                            duration: const Duration(milliseconds: 3000),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(
                              bottom: 24,
                              left: 16,
                              right: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: 'UNDO',
                              textColor: const Color(0xFF7BD0FF),
                              onPressed: () async {
                                await ref
                                    .read(attendanceRepositoryProvider.notifier)
                                    .insertRecord(backup);
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRecords = ref.watch(attendanceRepositoryProvider);
    final allSubjects = ref.watch(subjectRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final mutedTextColor = context.mutedTextColor;

    // Filter live records matching this calendar day
    final liveRecords = allRecords.where((r) {
      return r.date.year == summary.date.year &&
          r.date.month == summary.date.month &&
          r.date.day == summary.date.day;
    }).toList();

    final formattedDate =
        DateFormat('EEEE, MMMM d, yyyy').format(summary.date);
    final totalClasses = liveRecords.length;
    final presentClasses = liveRecords
        .where((r) => r.status.toLowerCase() == 'present')
        .length;
    final double percentage =
        totalClasses > 0 ? (presentClasses / totalClasses) * 100 : 0.0;

    final Color statusColor = percentage >= 75
        ? const Color(0xFF10B981)
        : (percentage >= 60
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444));

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalClasses > 0
                          ? '$presentClasses attended of $totalClasses classes'
                          : 'No recorded attendance for this day',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalClasses > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            height: 1,
          ),
          const SizedBox(height: 16),

          if (liveRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 40,
                      color: mutedTextColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No classes logged on this day',
                      style: TextStyle(color: subtextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...liveRecords.map((r) {
              final isPresent = r.status.toLowerCase() == 'present';
              final isAbsent = r.status.toLowerCase() == 'absent';
              final itemColor = isPresent
                  ? const Color(0xFF10B981)
                  : (isAbsent
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF8151EB));

              final subject = allSubjects
                  .cast<Subject?>()
                  .firstWhere((s) => s?.id == r.subjectId, orElse: () => null);
              final subjectName = subject?.name ?? r.subjectId.toUpperCase();

              final markedTimestamp =
                  r.updatedAt > 0 ? r.updatedAt : r.createdAt;
              final markedTime = markedTimestamp > 0
                  ? DateTime.fromMillisecondsSinceEpoch(markedTimestamp)
                  : r.date;
              final timeFormatted =
                  DateFormat('hh:mm a').format(markedTime);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(14),
                  borderColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: itemColor.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isPresent
                              ? Icons.check_rounded
                              : (isAbsent
                                  ? Icons.close_rounded
                                  : Icons.event_available_rounded),
                          color: itemColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjectName,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  timeFormatted,
                                  style: TextStyle(
                                    color: context.accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (r.periodNumber != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '• Period ${r.periodNumber}',
                                    style: TextStyle(
                                      color: mutedTextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.status.toUpperCase(),
                          style: TextStyle(
                            color: itemColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Delete attendance',
                        child: InkWell(
                          onTap: () => _confirmDeleteDayRecord(
                            context,
                            ref,
                            r,
                            subjectName,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.75),
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
