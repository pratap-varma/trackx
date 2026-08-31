import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/admin/providers/admin_providers.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Please enter both administrator email and password.');
      return;
    }

    setState(() => _localError = null);
    HapticFeedback.mediumImpact();

    final success = await ref.read(adminAuthStateProvider.notifier).login(email, password);

    if (mounted) {
      if (success) {
        context.go('/admin/dashboard');
      } else {
        final err = ref.read(adminAuthStateProvider).errorMessage ??
            'Access denied: Could not verify administrator privileges.';
        setState(() => _localError = err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthStateProvider);
    final isLoading = authState.status == AdminAuthStatus.loading;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.subtextColor),
            onPressed: () => context.go('/login'),
          ),
          title: Text(
            'Admin Portal',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Restricted Admin Shield Badge
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFFEF4444),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Restricted Access Level',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in with authorized administrator credentials to manage users and view telemetry.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.subtextColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  borderColor: context.subtleBorderColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADMINISTRATOR EMAIL',
                        style: TextStyle(
                          color: context.mutedTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GlassTextField(
                        controller: _emailController,
                        labelText: 'Administrator Email',
                        hintText: 'admin@trackx.app',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'PASSWORD',
                        style: TextStyle(
                          color: context.mutedTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GlassTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: '••••••••',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: context.mutedTextColor,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_localError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _localError!,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      GlassPrimaryButton(
                        text: isLoading ? 'Verifying Credentials...' : 'Authenticate Admin Session',
                        onPressed: isLoading ? null : _handleLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: Icon(Icons.arrow_back_rounded, size: 16, color: context.mutedTextColor),
                  label: Text(
                    'Return to Student Login',
                    style: TextStyle(color: context.subtextColor, fontSize: 13),
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
