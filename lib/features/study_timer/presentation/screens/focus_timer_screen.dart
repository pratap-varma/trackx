import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  int _completedCycles = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ringController;

  // Sessions in order: focus(25), break(5), focus(25), break(5), focus(25), long-break(15)
  static const _modes = [
    'Focus',
    'Short Break',
    'Focus',
    'Short Break',
    'Focus',
    'Long Break',
  ];
  static const _modeDurations = [
    25 * 60,
    5 * 60,
    25 * 60,
    5 * 60,
    25 * 60,
    15 * 60,
  ];
  int _modeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  int get _totalSeconds => _modeDurations[_modeIndex];
  double get _progress => _secondsRemaining / _totalSeconds;
  bool get _isFocusMode => _modeIndex % 2 == 0;

  void _startTimer() {
    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _onCycleComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRunning = false;
    });
  }

  void _onCycleComplete() {
    _timer?.cancel();
    _pulseController.stop();
    HapticFeedback.heavyImpact();
    setState(() {
      _isRunning = false;
      if (_isFocusMode) _completedCycles++;
      _modeIndex = (_modeIndex + 1) % _modes.length;
      _secondsRemaining = _modeDurations[_modeIndex];
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _modeDurations[_modeIndex];
    });
  }

  void _skipMode() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _modeIndex = (_modeIndex + 1) % _modes.length;
      _secondsRemaining = _modeDurations[_modeIndex];
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _modeColor =>
      _isFocusMode ? const Color(0xFF5B5FEF) : const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: context.textColor,
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Focus Timer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.textColor,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.skip_next_rounded,
                color: context.mutedTextColor,
                size: 22,
              ),
              onPressed: _skipMode,
              tooltip: 'Skip to next',
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),

            // Mode chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _modes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isActive = i == _modeIndex;
                  return GestureDetector(
                    onTap: () {
                      if (_isRunning) _pauseTimer();
                      setState(() {
                        _modeIndex = i;
                        _secondsRemaining = _modeDurations[i];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _modeColor.withValues(alpha: 0.2)
                            : (context.isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? _modeColor.withValues(alpha: 0.5)
                              : context.subtleBorderColor,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        _modes[i],
                        style: TextStyle(
                          color: isActive ? _modeColor : context.mutedTextColor,
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            // Ring timer
            Expanded(
              child: Center(
                child: ScaleTransition(
                  scale: _isRunning
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _FocusRingPainter(
                        progress: _progress,
                        color: _modeColor,
                        isBreak: !_isFocusMode,
                        isDark: context.isDark,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_secondsRemaining),
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 46,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _modes[_modeIndex],
                              style: TextStyle(
                                color: _modeColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Cycle dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final done = i < _completedCycles % 4;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: done ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: done
                        ? _modeColor
                        : (context.isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '$_completedCycles cycle${_completedCycles != 1 ? 's' : ''} completed',
              style: TextStyle(
                color: context.mutedTextColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 32),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Reset
                  GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: _resetTimer,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: context.subtextColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Play / Pause - big button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isRunning ? _pauseTimer : _startTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _modeColor,
                              _isFocusMode
                                  ? const Color(0xFF8151EB)
                                  : const Color(0xFF059669),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _modeColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isRunning ? 'Pause' : 'Start',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Skip next
                  GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: _skipMode,
                      child: Icon(
                        Icons.skip_next_rounded,
                        color: context.subtextColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_completedCycles',
                            style: TextStyle(
                              color: context.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Sessions',
                            style: TextStyle(
                              color: context.mutedTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Color(0xFF7BD0FF),
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(_completedCycles * 25)} min',
                            style: TextStyle(
                              color: context.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Focus Time',
                            style: TextStyle(
                              color: context.mutedTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.coffee_outlined,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(_completedCycles ~/ 4)} long',
                            style: TextStyle(
                              color: context.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Long Breaks',
                            style: TextStyle(
                              color: context.mutedTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isBreak;
  final bool isDark;

  _FocusRingPainter({
    required this.progress,
    required this.color,
    required this.isBreak,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1F2A3C) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    // Glow shadow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (1 - progress),
      false,
      glowPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    if (isBreak) {
      progressPaint.color = color;
    } else {
      progressPaint.shader = SweepGradient(
        colors: [color, const Color(0xFF8151EB), color],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (1 - progress),
      false,
      progressPaint,
    );

    // Tip dot
    if (progress < 1.0) {
      final angle = -math.pi / 2 + 2 * math.pi * (1 - progress);
      final tipX = center.dx + radius * math.cos(angle);
      final tipY = center.dy + radius * math.sin(angle);
      final dotPaint = Paint()..color = isDark ? Colors.white : const Color(0xFF1E293B);
      canvas.drawCircle(Offset(tipX, tipY), 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.progress != progress || old.color != color || old.isDark != isDark;
}
