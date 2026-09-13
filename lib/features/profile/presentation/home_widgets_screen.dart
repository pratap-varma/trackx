import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/core/services/widget_data_service.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/theme/app_theme.dart';

class HomeWidgetsScreen extends ConsumerStatefulWidget {
  const HomeWidgetsScreen({super.key});

  @override
  ConsumerState<HomeWidgetsScreen> createState() => _HomeWidgetsScreenState();
}

class _HomeWidgetsScreenState extends ConsumerState<HomeWidgetsScreen> {
  bool _isSyncing = false;
  String? _syncMessage;
  int _selectedInterval = 30;

  @override
  void initState() {
    super.initState();
    _selectedInterval = ref.read(widgetDataServiceProvider).getRefreshIntervalMinutes();
  }

  Future<void> _triggerSync() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    try {
      await ref.read(widgetDataServiceProvider).syncWithAppData(ref);
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncMessage = 'Widgets updated successfully with latest data!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncMessage = 'Sync failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetData = ref.watch(widgetDataServiceProvider).getWidgetData();

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textColor, size: 20),
                      onPressed: () => context.pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: context.cardColor,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home Screen Widgets',
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '3 specialized widgets for your Android launcher',
                            style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (_syncMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _syncMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Auto-Refresh Time Limit Card
                    _buildRefreshSettingsCard(context, widgetData),

                    const SizedBox(height: 24),

                    // 1. Attendance Widget Preview Card
                    _buildWidgetHeader(
                      number: '1',
                      title: 'Attendance Widget',
                      subtitle: 'Live attendance percentage, safe bunks & conducted ratios',
                      badgeColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 10),
                    _buildAttendancePreview(widgetData),

                    const SizedBox(height: 28),

                    // 2. Daily Schedule Widget Preview Card
                    _buildWidgetHeader(
                      number: '2',
                      title: 'Daily Schedule Widget',
                      subtitle: 'Displays all periods & lectures of today with timings & rooms',
                      badgeColor: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 10),
                    _buildSchedulePreview(widgetData),

                    const SizedBox(height: 28),

                    // 3. Exams & Events Widget Preview Card
                    _buildWidgetHeader(
                      number: '3',
                      title: 'Exams & Events Widget',
                      subtitle: 'Displays all exams, events & tasks for the upcoming week and month',
                      badgeColor: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 10),
                    _buildExamsPreview(widgetData),

                    const SizedBox(height: 32),

                    // How to add widgets instruction card
                    _buildInstructionsCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetHeader({
    required String number,
    required String title,
    required String subtitle,
    required Color badgeColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendancePreview(Map<String, dynamic> data) {
    final att = data['overallAttendance'] ?? '--%';
    final badge = data['attendanceBadge'] ?? 'ON TRACK';
    final bunk = data['attendanceBunkInfo'] ?? 'Safe to Bunk: -- classes';
    final target = data['attendanceTargetInfo'] ?? 'Target: 75%';
    final ratio = data['attendanceRatio'] ?? '-- / -- Conducted';
    final isDark = data['isDark'] as bool? ?? (Theme.of(context).brightness == Brightness.dark);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111726) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/images/app_logo.png', width: 18, height: 18, errorBuilder: (c, e, s) => const Icon(Icons.school_rounded, color: Colors.white, size: 18)),
              const SizedBox(width: 8),
              const Text(
                'ATTENDANCE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    att,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Overall Attendance',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              Container(
                height: 38,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bunk,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      target,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ratio,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
              const Text(
                'Tap to refresh ↻',
                style: TextStyle(
                  color: Color(0xFF7BD0FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePreview(Map<String, dynamic> data) {
    final day = data['scheduleDay'] ?? 'DAILY SCHEDULE';
    final badge = data['scheduleBadge'] ?? 'TODAY';
    final summary = data['scheduleSummary'] ?? 'Tap to view full timetable';
    final slotsRaw = data['scheduleSlotsJson'];
    List<dynamic> slots = [];
    if (slotsRaw != null) {
      try {
        slots = jsonDecode(slotsRaw);
      } catch (_) {}
    }

    final isDark = data['isDark'] as bool? ?? (Theme.of(context).brightness == Brightness.dark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111726) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/images/app_logo.png', width: 18, height: 18, errorBuilder: (c, e, s) => const Icon(Icons.school_rounded, color: Colors.white, size: 18)),
              const SizedBox(width: 8),
              Text(
                day,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (slots.isNotEmpty)
            Column(
              children: slots.take(4).map<Widget>((slot) {
                final badgeText = slot['badge'] ?? 'P1';
                final nameText = slot['name'] ?? 'Class';
                final timeText = slot['time'] ?? '';
                final statusText = slot['status'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Color(0xFF7BD0FF),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameText,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              timeText,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (statusText.isNotEmpty)
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusText == 'NOW' ? const Color(0xFF10B981) : const Color(0xFF7BD0FF),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Text(
                    'No classes scheduled today',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Enjoy your day off or check upcoming lectures',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  summary,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text(
                'Refresh ↻',
                style: TextStyle(
                  color: Color(0xFF7BD0FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamsPreview(Map<String, dynamic> data) {
    final header = data['examsHeader'] ?? 'EXAMS & EVENTS';
    final badge = data['examsBadge'] ?? 'SCHEDULED';
    final summary = data['examsSummary'] ?? '0 upcoming exams • 0 tasks pending';
    final examsRaw = data['examsSlotsJson'];
    List<dynamic> exams = [];
    if (examsRaw != null) {
      try {
        exams = jsonDecode(examsRaw);
      } catch (_) {}
    }

    final isDark = data['isDark'] as bool? ?? (Theme.of(context).brightness == Brightness.dark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111726) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/images/app_logo.png', width: 18, height: 18, errorBuilder: (c, e, s) => const Icon(Icons.school_rounded, color: Colors.white, size: 18)),
              const SizedBox(width: 8),
              Text(
                header,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (exams.isNotEmpty)
            Column(
              children: exams.take(4).map<Widget>((item) {
                final badgeText = item['badge'] ?? 'EXAM';
                final titleText = item['title'] ?? 'Event';
                final subtitleText = item['subtitle'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Color(0xFFC084FC),
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitleText,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Text(
                    'No Upcoming Exams or Events',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Add exams in Planner to track dates & deadlines',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  summary,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text(
                'Refresh ↻',
                style: TextStyle(
                  color: Color(0xFF7BD0FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return GlassContainer(
      tier: GlassTier.standard,
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app_rounded, color: context.accentColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'How to add widgets on Android',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepRow('1', 'Go to your phone\'s Home Screen and touch & hold any empty space.'),
          const SizedBox(height: 10),
          _buildStepRow('2', 'Tap Widgets from the popup menu.'),
          const SizedBox(height: 10),
          _buildStepRow('3', 'Scroll or search for TrackX.'),
          const SizedBox(height: 10),
          _buildStepRow('4', 'Touch & hold your preferred widget (Attendance, Daily Schedule, or Exams) and drag it to your screen.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.refresh_rounded, color: context.accentColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Tapping any widget on your home screen instantly refreshes its information! Tap the TrackX logo in the corner to open the app.',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshSettingsCard(BuildContext context, Map<String, dynamic> widgetData) {
    final lastUpdated = widgetData['lastUpdatedAt'] as num? ?? 0;
    String lastUpdatedStr = 'Never';
    if (lastUpdated > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastUpdated.toInt());
      final now = DateTime.now();
      final diffMins = now.difference(dt).inMinutes;
      if (diffMins <= 1) {
        lastUpdatedStr = 'Just now';
      } else if (diffMins < 60) {
        lastUpdatedStr = '$diffMins mins ago';
      } else {
        lastUpdatedStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_outlined, color: context.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Widget Refresh Interval',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Last refreshed: $lastUpdatedStr',
                      style: TextStyle(
                        color: context.subtextColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSyncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.accentColor),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Select how often widgets should automatically refresh data in the background:',
            style: TextStyle(
              color: context.subtextColor,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIntervalChip(15, '15 Mins'),
              const SizedBox(width: 8),
              _buildIntervalChip(30, '30 Mins (Default)'),
              const SizedBox(width: 8),
              _buildIntervalChip(60, '1 Hour'),
            ],
          ),
          const SizedBox(height: 16),
          GlassPrimaryButton(
            text: _isSyncing ? 'Refreshing Widgets...' : 'Refresh All Widgets Now',
            isLoading: _isSyncing,
            onPressed: _triggerSync,
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalChip(int minutes, String label) {
    final isSelected = _selectedInterval == minutes;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          setState(() {
            _selectedInterval = minutes;
          });
          await ref.read(widgetDataServiceProvider).setRefreshIntervalMinutes(minutes);
          ref.read(widgetDataServiceProvider).startPeriodicSync(ref);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Widget auto-refresh set to every $minutes minutes'),
                duration: const Duration(seconds: 2),
                backgroundColor: context.accentColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? context.accentColor : context.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? context.accentColor : context.subtextColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : context.textColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: context.accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              color: context.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.subtextColor,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
