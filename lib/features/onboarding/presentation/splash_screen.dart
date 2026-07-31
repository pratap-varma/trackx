import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/auth_header.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

    // Trigger redirection check after animation completes and auth state is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for the animation to complete
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final authState = ref.read(authRepositoryProvider);

    if (authState.status == AuthStatus.authenticated) {
      if (authState.userProfile?.onboardingCompleted == true) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuthHeader(
                  title: 'TrackX',
                  subtitle: 'Track Smarter. Plan Better.',
                ),
                SizedBox(height: 48),
                CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.purpleAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
