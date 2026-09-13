import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/attendance/domain/attendance_record_model.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/theme/app_theme.dart';

/// A beautiful bottom sheet showing subject attendance stats
/// matching the Luminous design mockup (Mark Present / Skip Class).
class SubjectActionSheet extends ConsumerStatefulWidget {
  final SubjectStats stats;
  final String activeSemId;

  const SubjectActionSheet({
    super.key,
    required this.stats,
    required this.activeSemId,
  });

  @override
  ConsumerState<SubjectActionSheet> createState() => _SubjectActionSheetState();
}

class _SubjectActionSheetState extends ConsumerState<SubjectActionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _markAndClose(String status) async {
    HapticFeedback.mediumImpact();
    final authState = ref.read(authRepositoryProvider);
    final userId = authState.userProfile?.id ?? 'guest';

    await ref
        .read(attendanceRepositoryProvider.notifier)
        .markAttendance(
          userId: userId,
          semesterId: widget.activeSemId,
          subjectId: widget.stats.subject.id,
          date: DateTime.now(),
          periodNumber: null,
          status: status,
        );

    if (mounted) Navigator.pop(context, status);
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.stats.subject;
    final pct = widget.stats.percentage;
    final safeBunks = widget.stats.safeBunks;
    final target = widget.stats.target;

    final total = widget.stats.totalCount;
    final present = widget.stats.presentCount;
    final pctIfPresent = total > 0
        ? ((present + 1) / (total + 1) * 100)
        : 100.0;
    final pctIfAbsent = total > 0 ? (present / (total + 1) * 100) : 0.0;

    final onTrack = pct >= target;
    final safeToBunk = safeBunks > 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final mutedTextColor = context.mutedTextColor;
    final today = DateTime.now();
    final allRecords = ref.watch(attendanceRepositoryProvider);
    final todayRecords = allRecords.where((r) =>
        r.subjectId == sub.id &&
        r.date.year == today.year &&
        r.date.month == today.month &&
        r.date.day == today.day).toList();

    const primaryBlue = Color(0xFF5B5FEF);
    const dangerRed = Color(0xFFEF4444);
    const successGreen = Color(0xFF10B981);

    return AnimatedBuilder(
      animation: _entryAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _entryAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(_entryAnimation),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 14, bottom: 20),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: mutedTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sub.facultyName.isNotEmpty
                            ? sub.facultyName
                            : 'Faculty',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Current Attendance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131A2B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT ATTENDANCE',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              onTrack ? 'On Track' : 'At Risk',
                              style: TextStyle(
                                color: onTrack ? successGreen : dangerRed,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // If Present / If Absent
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF131A2B)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up_rounded,
                                    size: 16,
                                    color: successGreen,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: successGreen.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${(pctIfPresent - pct).abs().toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: successGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'If Present',
                                style: TextStyle(
                                  color: mutedTextColor,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${pctIfPresent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF131A2B)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_down_rounded,
                                    size: 16,
                                    color: dangerRed,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dangerRed.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '-${(pct - pctIfAbsent).abs().toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: dangerRed,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'If Absent',
                                style: TextStyle(
                                  color: mutedTextColor,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${pctIfAbsent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Insight card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: safeToBunk
                          ? primaryBlue.withValues(alpha: 0.1)
                          : dangerRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: safeToBunk
                            ? primaryBlue.withValues(alpha: 0.3)
                            : dangerRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (safeToBunk ? primaryBlue : dangerRed)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            safeToBunk
                                ? Icons.auto_awesome_rounded
                                : Icons.warning_amber_rounded,
                            color: safeToBunk ? primaryBlue : dangerRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                safeToBunk ? 'SAFE-TO-MISS' : 'RECOVERY NEEDED',
                                style: TextStyle(
                                  color: safeToBunk ? primaryBlue : dangerRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                safeToBunk
                                    ? 'You can skip $safeBunks more class${safeBunks != 1 ? "es" : ""} and stay above your ${target.toStringAsFixed(0)}% target.'
                                    : 'Attend ${widget.stats.requiredRecovery} more class${widget.stats.requiredRecovery != 1 ? "es" : ""} to reach ${target.toStringAsFixed(0)}%.',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mark Present
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _markAndClose('present'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.how_to_reg_rounded, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Mark Present',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Skip Class
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _markAndClose('absent'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.airplanemode_active_rounded, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Skip Class',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Delete Today's Attendance (if marked)
                  if (todayRecords.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final backup = List<AttendanceRecord>.from(todayRecords);
                          for (final r in todayRecords) {
                            await ref
                                .read(attendanceRepositoryProvider.notifier)
                                .deleteAttendance(r.id);
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Today's attendance cleared for ${sub.name}."),
                                duration: const Duration(milliseconds: 3000),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: const Color(0xFF7BD0FF),
                                  onPressed: () async {
                                    for (final r in backup) {
                                      await ref
                                          .read(attendanceRepositoryProvider.notifier)
                                          .insertRecord(r);
                                    }
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: dangerRed,
                        ),
                        label: const Text(
                          "Delete Today's Attendance",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: dangerRed,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dangerRed,
                          side: BorderSide(
                            color: dangerRed.withValues(alpha: 0.4),
                          ),
                          backgroundColor:
                              dangerRed.withValues(alpha: isDark ? 0.12 : 0.08),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Take Note / Detailed Statistics
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        GoRouter.of(context).push('/subject-detail/${widget.stats.subject.id}');
                      },
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: Color(0xFF5B5FEF),
                      ),
                      label: const Text(
                        'Take Note / View Statistics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF5B5FEF),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFF5B5FEF).withValues(alpha: 0.4),
                        ),
                        backgroundColor:
                            const Color(0xFF5B5FEF).withValues(alpha: isDark ? 0.12 : 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen overlay shown after marking attendance, matching mockup design
class AttendanceLoggedOverlay extends StatefulWidget {
  final String subjectName;
  final String subjectCode;
  final double newPercentage;
  final double change;
  final VoidCallback onDismiss;

  const AttendanceLoggedOverlay({
    super.key,
    required this.subjectName,
    required this.subjectCode,
    required this.newPercentage,
    required this.change,
    required this.onDismiss,
  });

  @override
  State<AttendanceLoggedOverlay> createState() =>
      _AttendanceLoggedOverlayState();
}

class _AttendanceLoggedOverlayState extends State<AttendanceLoggedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _checkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final mutedTextColor = context.mutedTextColor;

    return Material(
      color: isDark ? const Color(0xEA0A1020) : const Color(0xEAFFFFFF),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Concentric rings + check icon
                ScaleTransition(
                  scale: _scaleAnim,
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: _ConcentricRingsPainter(isDark: isDark),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _checkAnim,
                          builder: (context, _) {
                            return Opacity(
                              opacity: _checkAnim.value,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1A2A5E)
                                      : const Color(0xFFE8EDFF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF5B5FEF),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF5B5FEF),
                                  size: 36,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Attendance Logged!',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You're on track for your 4.0 goal.",
                  style: TextStyle(color: subtextColor, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Subject card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.science_outlined,
                          color: mutedTextColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subjectName,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              widget.subjectCode,
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${widget.newPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Color(0xFF5B5FEF),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                size: 12,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '+${widget.change.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B5FEF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Back to Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcentricRingsPainter extends CustomPainter {
  final bool isDark;

  _ConcentricRingsPainter({this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final radius in [88.0, 72.0, 56.0]) {
      final paint = Paint()
        ..color = (isDark ? const Color(0xFF1A2A5E) : const Color(0xFF5B5FEF))
            .withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, radius, paint);
    }
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF12215C) : const Color(0xFFE8EDFF))
              .withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 90));
    canvas.drawCircle(center, 90, bgPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
