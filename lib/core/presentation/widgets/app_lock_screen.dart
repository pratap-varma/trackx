import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/core/services/app_lock_service.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback? onUnlocked;

  const AppLockScreen({super.key, this.onUnlocked});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-prompt biometrics if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  Future<void> _tryBiometricUnlock() async {
    final lockState = ref.read(appLockProvider);
    if (lockState.isBiometricsEnabled) {
      final success = await ref.read(appLockProvider.notifier).authenticateBiometric();
      if (success && mounted) {
        widget.onUnlocked?.call();
      }
    }
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      if (_enteredPin.length < 4) {
        _enteredPin += digit;
        if (_enteredPin.length == 4) {
          _verifyPin();
        }
      }
    });
  }

  void _onDeletePressed() {
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      }
    });
  }

  Future<void> _verifyPin() async {
    final success =
        await ref.read(appLockProvider.notifier).verifyPin(_enteredPin);
    if (!mounted) return;
    if (success) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked?.call();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Incorrect PIN. Try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // App Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF5B5FEF).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFFC0C1FF),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'TrackX App Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lockState.isTemporarilyLockedOut
                      ? 'Too many failed attempts. Try again in ${lockState.remainingLockoutSeconds}s'
                      : 'Enter your 4-digit PIN or use Biometrics to unlock',
                  style: TextStyle(
                    color: lockState.isTemporarilyLockedOut
                        ? const Color(0xFFEF4444)
                        : Colors.white60,
                    fontSize: 12,
                    fontWeight: lockState.isTemporarilyLockedOut
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? const Color(0xFF5B5FEF) : Colors.transparent,
                        border: Border.all(
                          color: isFilled ? const Color(0xFF5B5FEF) : Colors.white30,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                if (_errorMessage != null && !lockState.isTemporarilyLockedOut) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // Keypad
                Opacity(
                  opacity: lockState.isTemporarilyLockedOut ? 0.35 : 1.0,
                  child: IgnorePointer(
                    ignoring: lockState.isTemporarilyLockedOut,
                    child: _buildKeypad(lockState),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(AppLockState lockState) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (lockState.isBiometricsEnabled)
              SizedBox(
                width: 72,
                height: 64,
                child: IconButton(
                  onPressed: _tryBiometricUnlock,
                  icon: const Icon(
                    Icons.fingerprint_rounded,
                    color: Color(0xFF7BD0FF),
                    size: 32,
                  ),
                ),
              )
            else
              const SizedBox(width: 72, height: 64),
            _buildKey('0'),
            SizedBox(
              width: 72,
              height: 64,
              child: IconButton(
                onPressed: _onDeletePressed,
                icon: const Icon(
                  Icons.backspace_outlined,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value) {
    return Container(
      width: 72,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF131A2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _onDigitPressed(value),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
