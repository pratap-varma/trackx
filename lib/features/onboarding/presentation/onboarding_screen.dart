import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  int _selectedSemester = 1;
  double _selectedTarget = 75.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final branch = _branchController.text.trim();

    await ref
        .read(authRepositoryProvider.notifier)
        .completeOnboarding(name, branch, _selectedSemester, _selectedTarget);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final presets = [75.0, 80.0, 85.0, 90.0];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'Setup Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Customize your semester and target parameters',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  // Profile setup glass card
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Name
                        GlassTextField(
                          controller: _nameController,
                          labelText: 'Your Name',
                          hintText: 'John Doe',
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Branch
                        GlassTextField(
                          controller: _branchController,
                          labelText: 'Course / Branch',
                          hintText: 'B.Tech CSE',
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Branch/Course is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Semester Select
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Semester',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<int>(
                                value: _selectedSemester,
                                dropdownColor: AppTheme.darkBgBase,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                items: List.generate(8, (i) => i + 1).map((
                                  sem,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: sem,
                                    child: Text('Sem $sem'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedSemester = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 12),

                        // Target Attendance Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Target Attendance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${_selectedTarget.toInt()}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentPurple,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _selectedTarget,
                          min: 1.0,
                          max: 100.0,
                          divisions: 99,
                          activeColor: AppTheme.accentPurple,
                          inactiveColor: Colors.white10,
                          onChanged: (val) {
                            setState(() {
                              _selectedTarget = val;
                            });
                          },
                        ),

                        // Presets Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: presets.map((p) {
                            final isActive = _selectedTarget == p;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTarget = p;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.accentPurple.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: isActive
                                        ? AppTheme.accentPurple
                                        : Colors.white12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${p.toInt()}%',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white60,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Profile Button
                  GlassPrimaryButton(
                    text: 'Complete Setup',
                    isLoading: _isLoading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
