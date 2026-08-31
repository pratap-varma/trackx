import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/attendance/domain/models/attendance_heatmap_models.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

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
              style: const TextStyle(
                color: Colors.white54,
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
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Jump to Today Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_view_month_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ATTENDANCE ACTIVITY',
                    style: TextStyle(
                      color: Colors.white,
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
                          size: 11, color: Color(0xFFC0C1FF)),
                      SizedBox(width: 4),
                      Text(
                        'Today',
                        style: TextStyle(
                          color: Color(0xFFC0C1FF),
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
                    _weekdayLabel('S'),
                    _weekdayLabel('M'),
                    _weekdayLabel('T'),
                    _weekdayLabel('W'),
                    _weekdayLabel('T'),
                    _weekdayLabel('F'),
                    _weekdayLabel('S'),
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
                                              ? Colors.white
                                                  .withValues(alpha: 0.02)
                                              : summary.statusColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isToday
                                                ? const Color(0xFF7BD0FF)
                                                : (summary.totalClasses > 0
                                                    ? Colors.white.withValues(
                                                        alpha: 0.15)
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
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendItem(const Color(0xFF10B981), '100%'),
                  const SizedBox(width: 8),
                  _legendItem(const Color(0xFF3B82F6), 'Partial'),
                  const SizedBox(width: 8),
                  _legendItem(const Color(0xFFEF4444), 'Missed'),
                  const SizedBox(width: 8),
                  _legendItem(const Color(0xFF8151EB), 'Off/Event'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weekdayLabel(String label) {
    return Container(
      height: 20,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
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
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}

class _DayAttendanceBreakdownSheet extends StatelessWidget {
  final DayAttendanceSummary summary;

  const _DayAttendanceBreakdownSheet({required this.summary});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE, MMMM d, yyyy').format(summary.date);
    final percentage = summary.percentage.toInt();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E1628),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Colors.white.withValues(alpha: 0.15),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.totalClasses > 0
                          ? '${summary.presentClasses} attended of ${summary.totalClasses} classes'
                          : 'No recorded attendance for this day',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (summary.totalClasses > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: summary.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: summary.statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: summary.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),

          if (summary.records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No classes logged on this day',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...summary.records.map((r) {
              final isPresent = r.status.toLowerCase() == 'present';
              final isAbsent = r.status.toLowerCase() == 'absent';
              final statusColor = isPresent
                  ? const Color(0xFF10B981)
                  : (isAbsent
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF8151EB));

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(14),
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isPresent
                              ? Icons.check_rounded
                              : (isAbsent
                                  ? Icons.close_rounded
                                  : Icons.event_available_rounded),
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.subjectId.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            if (r.periodNumber != null)
                              Text(
                                'Slot / Period ${r.periodNumber}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
