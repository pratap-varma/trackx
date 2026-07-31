import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _targetController = TextEditingController();
  final _collegeController = TextEditingController();
  final _gradYearController = TextEditingController();

  String _selectedLanguage = 'en';
  String _selectedTimezone = 'UTC';

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _targetController.dispose();
    _collegeController.dispose();
    _gradYearController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog(
    String currentName,
    String currentBranch,
    double currentTarget,
    String? currentCollege,
    int? currentGradYear,
    String? currentLang,
    String? currentTZ,
  ) {
    _nameController.text = currentName;
    _branchController.text = currentBranch;
    _targetController.text = currentTarget.toInt().toString();
    _collegeController.text = currentCollege ?? '';
    _gradYearController.text = currentGradYear?.toString() ?? '';
    _selectedLanguage = currentLang ?? 'en';
    _selectedTimezone = currentTZ ?? 'UTC';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _nameController,
                    labelText: 'Name',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _branchController,
                    labelText: 'Branch',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _collegeController,
                    labelText: 'College Name',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _gradYearController,
                    labelText: 'Expected Graduation Year',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _targetController,
                    labelText: 'Global Target (%)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.purple.shade900,
                    value: _selectedLanguage,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English (en)')),
                      DropdownMenuItem(value: 'es', child: Text('Español (es)')),
                      DropdownMenuItem(value: 'fr', child: Text('Français (fr)')),
                      DropdownMenuItem(value: 'de', child: Text('Deutsch (de)')),
                    ],
                    onChanged: (val) => setState(() => _selectedLanguage = val ?? 'en'),
                    decoration: InputDecoration(
                      labelText: 'Language',
                      labelStyle: const TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.purple.shade900,
                    value: _selectedTimezone,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                      DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata (IST)')),
                      DropdownMenuItem(value: 'America/New_York', child: Text('America/New_York (EST)')),
                      DropdownMenuItem(value: 'Europe/London', child: Text('Europe/London (GMT)')),
                    ],
                    onChanged: (val) => setState(() => _selectedTimezone = val ?? 'UTC'),
                    decoration: InputDecoration(
                      labelText: 'Timezone',
                      labelStyle: const TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final name = _nameController.text.trim();
                          final branch = _branchController.text.trim();
                          final college = _collegeController.text.trim();
                          final gradYear = int.tryParse(_gradYearController.text.trim());
                          final target = double.tryParse(_targetController.text.trim());

                          if (name.isNotEmpty && branch.isNotEmpty && target != null) {
                            await ref.read(authRepositoryProvider.notifier).updateProfile(
                                  name,
                                  branch,
                                  ref.read(authRepositoryProvider).userProfile?.semester ?? 1,
                                  target,
                                  collegeName: college.isNotEmpty ? college : null,
                                  expectedGraduationYear: gradYear,
                                  preferredLanguage: _selectedLanguage,
                                  preferredTimezone: _selectedTimezone,
                                );
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Clear All Local Data?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to permanently erase all locally cached semesters, subjects, attendance logs, and planner events?',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(semesterRepositoryProvider.notifier).restore([]);
                        await ref.read(subjectRepositoryProvider.notifier).restore([]);
                        await ref.read(attendanceRepositoryProvider.notifier).restore([]);
                        ref.read(tasksProvider.notifier).restore([]);
                        ref.read(examsProvider.notifier).restore([]);
                        ref.read(assignmentsProvider.notifier).restore([]);
                        ref.read(notesProvider.notifier).restore([]);

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All local data cleared successfully.')));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authRepositoryProvider);
    final profile = authState.userProfile;

    final name = profile?.name ?? 'Student';
    final email = profile?.email ?? 'Unknown';
    final branch = profile?.branch ?? 'None';
    final semester = profile?.semester ?? 1;
    final target = profile?.globalTarget ?? 75.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings & Profile',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  const Text(
                    'Manage academic targets & preferences',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _showEditProfileDialog(
                  name,
                  branch,
                  target,
                  profile?.collegeName,
                  profile?.expectedGraduationYear,
                  profile?.preferredLanguage,
                  profile?.preferredTimezone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User info Summary
          GlassContainer(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', name),
                const Divider(color: Colors.white10),
                _buildInfoRow('Email', email),
                const Divider(color: Colors.white10),
                _buildInfoRow('Branch / Course', branch),
                const Divider(color: Colors.white10),
                _buildInfoRow('Semester', 'Semester $semester'),
                const Divider(color: Colors.white10),
                _buildInfoRow('Global Target', '${target.toInt()}%'),
                const Divider(color: Colors.white10),
                _buildInfoRow('College Name', profile?.collegeName ?? 'Not Set'),
                const Divider(color: Colors.white10),
                _buildInfoRow('Graduation Year', '${profile?.expectedGraduationYear ?? "Not Set"}'),
                const Divider(color: Colors.white10),
                _buildInfoRow('Preferred Timezone', profile?.preferredTimezone ?? 'UTC'),
                const Divider(color: Colors.white10),
                _buildInfoRow('Language', profile?.preferredLanguage ?? 'en'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary features / Hub Links
          const Text('Academics & Search', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
          const SizedBox(height: 12),
          _buildHubLink(
            icon: Icons.school_rounded,
            title: 'Academic Planning Hub',
            route: '/academics',
          ),
          const SizedBox(height: 12),
          _buildHubLink(
            icon: Icons.search_rounded,
            title: 'Global Offline Search',
            route: '/search',
          ),
          const SizedBox(height: 24),

          // Legacy / Configuration links
          const Text('Other Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
          const SizedBox(height: 12),
          _buildHubLink(icon: Icons.calendar_month, title: 'Manage Semesters', route: '/semester-manage'),
          const SizedBox(height: 12),
          _buildHubLink(icon: Icons.schedule_rounded, title: 'Weekly Timetable', route: '/timetable'),
          const SizedBox(height: 12),
          _buildHubLink(icon: Icons.notes_rounded, title: 'My Study Notes', route: '/notes'),
          const SizedBox(height: 12),
          _buildHubLink(icon: Icons.backup_rounded, title: 'Backup & Restore Data', route: '/backup'),
          const SizedBox(height: 12),
          _buildHubLink(icon: Icons.timer_rounded, title: 'Study Focus Timer', route: '/focus-timer'),
          const SizedBox(height: 12),
          _buildHubLink(icon: Icons.location_on_rounded, title: 'Classroom Geofences', route: '/classrooms'),
          const SizedBox(height: 12),
          _buildHubLink(icon: Icons.feedback_rounded, title: 'Send Feedback & Diagnostics', route: '/feedback'),
          const SizedBox(height: 24),

          // Privacy Controls
          const Text('Privacy & Security', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
          const SizedBox(height: 12),
          GlassContainer(
            width: double.infinity,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cloud Sync Enabled', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Switch(
                      value: profile?.cloudSyncEnabled ?? false,
                      onChanged: (val) async {
                        await ref.read(authRepositoryProvider.notifier).updateProfile(
                              name,
                              branch,
                              semester,
                              target,
                              cloudSyncEnabled: val,
                            );
                      },
                      activeColor: AppTheme.accentPurple,
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clear All Local Cache', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Erase all offline schedules, semesters, and subjects.', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    trailing: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    onTap: _showClearDataDialog,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          GlassPrimaryButton(
            text: 'Sign Out',
            onPressed: () async {
              await ref.read(authRepositoryProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHubLink({
    required IconData icon,
    required String title,
    required String route,
  }) {
    return GlassContainer(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
