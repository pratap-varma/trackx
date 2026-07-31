import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/theme/app_theme.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedCycles = 0;

  DateTime? _backgroundTime;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onCycleComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _backgroundTime = DateTime.now(); // Record current timestamp
    });
  }

  void _resumeTimer() {
    if (_backgroundTime != null) {
      // Calculate elapsed seconds since pause for background persistence emulation
      final elapsed = DateTime.now().difference(_backgroundTime!).inSeconds;
      setState(() {
        _secondsRemaining = (_secondsRemaining - elapsed).clamp(0, 25 * 60);
      });
      _backgroundTime = null;
    }
    _startTimer();
  }

  void _onCycleComplete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (!_isBreak) {
        _isBreak = true;
        _secondsRemaining = 5 * 60; // 5 min break
        _completedCycles++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Great work! Time for a short break.')),
        );
      } else {
        _isBreak = false;
        _secondsRemaining = 25 * 60; // 25 min focus
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Break over! Let\'s focus again.')),
        );
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _secondsRemaining = 25 * 60;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsRemaining / (_isBreak ? 5 * 60 : 25 * 60);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Focus Timer',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            children: [
              GlassContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isBreak ? 'Break Session' : 'Focus Session',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.accentPurple,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Completed Cycles: $_completedCycles',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_isRunning)
                          IconButton(
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                            onPressed: _startTimer,
                          )
                        else
                          IconButton(
                            icon: const Icon(
                              Icons.pause_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                            onPressed: _pauseTimer,
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white70,
                            size: 28,
                          ),
                          onPressed: _resetTimer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
