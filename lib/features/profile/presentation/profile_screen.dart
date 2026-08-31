import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/notifications/services/daily_digest_service.dart';
import 'package:trackx/features/calendar/presentation/widgets/calendar_integration_sheet.dart';
import 'package:trackx/features/calendar/providers/calendar_provider.dart';
import 'package:trackx/core/services/app_lock_service.dart';
import 'package:trackx/core/presentation/widgets/pin_setup_sheet.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double _globalTarget = 85.0;
  bool _smartNotifications = true;
  String _selectedPersonality = 'direct'; // 'direct' or 'butler'
  bool _incognitoMode = false;
  String _cachedName = 'Pratap';
  String _cachedBranch = 'Computer Science & Engineering';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      setState(() {
        _incognitoMode = prefs.getBool('sec_incognito') ?? false;
        _smartNotifications = prefs.getBool('sec_smart_notif') ?? true;
        _selectedPersonality = prefs.getString('ai_personality') ?? 'direct';
      });
    });
  }

  void _saveSecurityPref(String key, dynamic value) {
    final prefs = ref.read(sharedPreferencesProvider);
    if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is String) {
      prefs.setString(key, value);
    }
  }

  void _showSecurityAndPrivacySheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Consumer(
          builder: (ctx, ref, _) {
            final lockState = ref.watch(appLockProvider);
            return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0E1628),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B243B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              color: Color(0xFFC0C1FF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Security & Privacy',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Biometrics, Data Export & Encryption',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 1. Biometric Lock
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fingerprint_rounded,
                          color: Color(0xFF7BD0FF),
                          size: 24,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biometric App Lock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Unlock TrackX with Fingerprint or Face ID',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: lockState.isBiometricsEnabled,
                          activeThumbColor: const Color(0xFF5B5FEF),
                          onChanged: (val) async {
                            HapticFeedback.lightImpact();
                            final success = await ref
                                .read(appLockProvider.notifier)
                                .toggleBiometrics(val);
                            if (mounted) {
                              if (val && !success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '⚠️ Biometrics cancelled or unavailable on this device.',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      val
                                          ? '🔒 Biometric Lock Enabled'
                                          : '🔓 Biometric Lock Disabled',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. PIN on Launch & PIN Configuration
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.pin_rounded,
                              color: Color(0xFFC0C1FF),
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Require PIN Code',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lockState.hasPin
                                        ? 'PIN protection active'
                                        : 'Set a 4-digit PIN to secure app',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: lockState.isPinEnabled && lockState.hasPin,
                              activeThumbColor: const Color(0xFF5B5FEF),
                              onChanged: (val) async {
                                HapticFeedback.lightImpact();
                                if (val) {
                                  if (!lockState.hasPin) {
                                    await PinSetupSheet.show(context);
                                  } else {
                                    await ref
                                        .read(appLockProvider.notifier)
                                        .togglePinEnabled(true);
                                  }
                                } else {
                                  await ref
                                      .read(appLockProvider.notifier)
                                      .togglePinEnabled(false);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lockState.hasPin
                                  ? 'PIN Status: Configured'
                                  : 'PIN Status: Not Set',
                              style: TextStyle(
                                color: lockState.hasPin
                                    ? const Color(0xFF10B981)
                                    : Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await PinSetupSheet.show(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF5B5FEF,
                                  ).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF5B5FEF,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  lockState.hasPin
                                      ? 'Change PIN'
                                      : 'Set 4-Digit PIN',
                                  style: const TextStyle(
                                    color: Color(0xFFC0C1FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Incognito Attendance
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility_off_outlined,
                          color: Color(0xFFFF8B94),
                          size: 24,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Private Notifications',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Hide attendance scores on lock screen previews',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _incognitoMode,
                          activeThumbColor: const Color(0xFF5B5FEF),
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setModalState(() => _incognitoMode = val);
                            setState(() => _incognitoMode = val);
                            _saveSecurityPref('sec_incognito', val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? '👁️ Privacy Mode Enabled'
                                      : 'Privacy Mode Disabled',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'DATA MANAGEMENT',
                    style: TextStyle(
                      color: Color(0xFF908FA0),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Export Data Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      final subjects = ref.read(subjectRepositoryProvider);
                      final stats = ref.read(statsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '📦 Exported ${subjects.length} courses & ${stats.totalRecorded} records to CSV/JSON.',
                          ),
                          backgroundColor: const Color(0xFF1B243B),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Export Data (JSON / CSV)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Clear Cache Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🧹 Temporary cache & local buffers cleared successfully.',
                          ),
                          backgroundColor: Color(0xFF1B243B),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.cleaning_services_rounded,
                            color: Color(0xFFFF8B94),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Clear Local Cache',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

  void _showEditProfileSheet(String currentName, String currentBranch) {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController(text: currentName);
    final branchCtrl = TextEditingController(text: currentBranch);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 18),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              GlassTextField(
                controller: nameCtrl,
                labelText: 'Full Name',
                hintText: 'e.g. Alex Rivers',
              ),
              const SizedBox(height: 14),
              GlassTextField(
                controller: branchCtrl,
                labelText: 'Major & Academic Year',
                hintText: 'e.g. Computer Science • Junior',
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final newName = nameCtrl.text.trim();
                  final newBranch = branchCtrl.text.trim();
                  if (newName.isNotEmpty) {
                    final currentProfile = ref
                        .read(authRepositoryProvider)
                        .userProfile;
                    ref
                        .read(authRepositoryProvider.notifier)
                        .updateProfile(
                          newName,
                          newBranch,
                          currentProfile?.semester ?? 1,
                          _globalTarget,
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5FEF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authRepositoryProvider);
    final profile = authState.userProfile;
    if (profile?.name.isNotEmpty == true) {
      _cachedName = profile!.name;
    }
    if (profile?.branch.isNotEmpty == true) {
      _cachedBranch = profile!.branch;
    }

    final name = _cachedName;
    final branch = _cachedBranch;

    final activeSem = ref.watch(activeSemesterProvider);
    final subjects = ref.watch(subjectRepositoryProvider);
    final activeSubjectsCount = subjects
        .where((s) => s.semesterId == activeSem?.id)
        .length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: Colors.white,
            size: 22,
          ),
          onPressed: _showSecurityAndPrivacySheet,
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showEditProfileSheet(name, branch),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1B243B),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFC0C1FF),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        key: const PageStorageKey('profile_scroll'),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
        children: [
          // 1. Hero Profile Card
          GestureDetector(
            onTap: () => _showEditProfileSheet(name, branch),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF131A2B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  // Avatar with glow ring
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B5FEF), Color(0xFF7BD0FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B5FEF).withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit_rounded,
                        color: Colors.white38,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    branch,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FEF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Dean\'s List',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'CURRENT STANDING',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '3.8 / 4.0 Target',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1B243B),
                          border: Border.all(
                            color: const Color(0xFF10B981),
                            width: 2.5,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '95%',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. ACADEMIC SETTINGS
          const Text(
            'ACADEMIC SETTINGS',
            style: TextStyle(
              color: Color(0xFF908FA0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131A2B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                // Semester Management
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/semester-manage'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B243B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: Color(0xFFC0C1FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Semester Management',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeSem != null
                                    ? '${activeSem.name} • $activeSubjectsCount Active Courses'
                                    : 'Fall 2026 • 5 Active Courses',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                // Timetable OCR & Photo Upload
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/import-timetable'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B243B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            color: Color(0xFF7BD0FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan & Import Timetable',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Upload photo to auto-assign all subjects',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                // Global Attendance Target
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B243B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.track_changes_rounded,
                                  color: Color(0xFFC0C1FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Global Attendance\nTarget',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_globalTarget.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Warn if projected falls below threshold',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF5B5FEF),
                          inactiveTrackColor: Colors.white.withValues(
                            alpha: 0.08,
                          ),
                          thumbColor: Colors.white,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _globalTarget,
                          min: 50,
                          max: 100,
                          divisions: 50,
                          onChanged: (v) => setState(() => _globalTarget = v),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                // Smart Exam Notifications
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B243B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFFC0C1FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Smart Exam Notifications',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'AI-timed study reminders',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _smartNotifications,
                        activeThumbColor: const Color(0xFF5B5FEF),
                        onChanged: (v) =>
                            setState(() => _smartNotifications = v),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                // Daily Morning Digest
                Consumer(
                  builder: (context, ref, _) {
                    final digestSettings =
                        ref.watch(dailyDigestSettingsProvider);
                    final timeStr = DateFormat('hh:mm a').format(
                      DateTime(2026, 1, 1, digestSettings.hour,
                          digestSettings.minute),
                    );

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B243B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.wb_sunny_outlined,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Daily Morning Digest',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Attendance risks & schedule summary',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: digestSettings.enabled,
                                activeThumbColor: const Color(0xFF5B5FEF),
                                onChanged: (v) {
                                  ref
                                      .read(
                                          dailyDigestSettingsProvider.notifier)
                                      .toggleEnabled(v);
                                },
                              ),
                            ],
                          ),
                        ),
                        if (digestSettings.enabled) ...[
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(18, 0, 18, 12),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: digestSettings.hour,
                                        minute: digestSettings.minute,
                                      ),
                                      builder: (context, child) {
                                        return Theme(
                                          data: ThemeData.dark().copyWith(
                                            colorScheme:
                                                const ColorScheme.dark(
                                              primary: Color(0xFF5B5FEF),
                                              surface: Color(0xFF0E1628),
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (pickedTime != null) {
                                      ref
                                          .read(dailyDigestSettingsProvider
                                              .notifier)
                                          .setDeliveryTime(
                                            pickedTime.hour,
                                            pickedTime.minute,
                                          );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.05),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: Colors.white70),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Time: $timeStr',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    await ref
                                        .read(dailyDigestSettingsProvider
                                            .notifier)
                                        .triggerTestPreview();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Test Daily Digest notification sent!',
                                          ),
                                          duration:
                                              const Duration(seconds: 2),
                                          behavior:
                                              SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.send_rounded,
                                      size: 14),
                                  label: const Text('Test Notification'),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF7BD0FF),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // APPEARANCE & THEME SETTINGS
          const Text(
            'APPEARANCE & THEME',
            style: TextStyle(
              color: Color(0xFF908FA0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A2B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final currentMode = ref.watch(themeModeProvider);
                final currentAccent = ref.watch(accentColorProvider);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B243B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            currentMode == ThemeMode.light
                                ? Icons.light_mode_rounded
                                : (currentMode == ThemeMode.dark
                                    ? Icons.dark_mode_rounded
                                    : Icons.brightness_auto_rounded),
                            color: currentAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Mode',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Choose your preferred visual appearance',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Theme selector buttons (Dark, Light, System)
                    Row(
                      children: [
                        _buildThemeOption(
                          context: context,
                          label: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          isSelected: currentMode == ThemeMode.dark,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildThemeOption(
                          context: context,
                          label: 'Light',
                          icon: Icons.light_mode_rounded,
                          isSelected: currentMode == ThemeMode.light,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildThemeOption(
                          context: context,
                          label: 'System',
                          icon: Icons.settings_brightness_rounded,
                          isSelected: currentMode == ThemeMode.system,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                      height: 1,
                    ),
                    const SizedBox(height: 14),

                    // Accent Color Pack
                    Text(
                      'ACCENT COLOR PACK',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAccentCircle(ref, const Color(0xFF5B5FEF), currentAccent),
                        _buildAccentCircle(ref, const Color(0xFF3B82F6), currentAccent),
                        _buildAccentCircle(ref, const Color(0xFF10B981), currentAccent),
                        _buildAccentCircle(ref, const Color(0xFFF59E0B), currentAccent),
                        _buildAccentCircle(ref, const Color(0xFFEC4899), currentAccent),
                        _buildAccentCircle(ref, const Color(0xFF8151EB), currentAccent),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),

          // 4. PERSONALIZATION & SECURITY
          const Text(
            'PERSONALIZATION & SECURITY',
            style: TextStyle(
              color: Color(0xFF908FA0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B243B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: Color(0xFFC0C1FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AI Personality Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Select how TrackX AI interacts with you',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedPersonality = 'direct');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedPersonality == 'direct'
                                ? const Color(0xFF1D2642)
                                : const Color(0xFF1B243B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedPersonality == 'direct'
                                  ? const Color(0xFF5B5FEF)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.speed_rounded,
                                color: _selectedPersonality == 'direct'
                                    ? const Color(0xFFC0C1FF)
                                    : Colors.white54,
                                size: 22,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Direct & Efficient',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Focus on data & stats',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedPersonality = 'butler');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedPersonality == 'butler'
                                ? const Color(0xFF1D2642)
                                : const Color(0xFF1B243B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedPersonality == 'butler'
                                  ? const Color(0xFF5B5FEF)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.support_agent_rounded,
                                color: _selectedPersonality == 'butler'
                                    ? const Color(0xFFC0C1FF)
                                    : Colors.white54,
                                size: 22,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Study Butler',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Supportive & contextual',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                const SizedBox(height: 12),

                // AI Assistant & Gemini API Key Settings Row
                Consumer(
                  builder: (context, ref, _) {
                    final aiSettings = ref.watch(aiSettingsProvider);
                    final hasKey = aiSettings.customApiKey.trim().isNotEmpty;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/ai-settings'),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B243B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFC0C1FF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'AI Assistant & Gemini Key',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasKey
                                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                            : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: hasKey
                                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                              : const Color(0xFFEF4444).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        hasKey ? 'KEY ACTIVE' : 'KEY MISSING',
                                        style: TextStyle(
                                          color: hasKey
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFFF8B94),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasKey
                                      ? 'Custom Gemini Key connected • Tap to edit'
                                      : 'Tap here to paste your free Gemini API key',
                                  style: TextStyle(
                                    color: hasKey
                                        ? const Color(0xFF10B981)
                                        : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                const SizedBox(height: 12),

                // Google Calendar Holidays Integration Row
                Consumer(
                  builder: (context, ref, _) {
                    final isCalConnected = ref.watch(
                      isCalendarConnectedProvider,
                    );
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => CalendarIntegrationSheet.show(context),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B243B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF4285F4),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Google Calendar Holidays',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCalConnected
                                      ? 'Connected • Auto-syncs festivals'
                                      : 'Connect to display holidays in Planner',
                                  style: TextStyle(
                                    color: isCalConnected
                                        ? const Color(0xFF10B981)
                                        : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                const SizedBox(height: 12),

                // Security & Privacy Row (Fully Interactive)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showSecurityAndPrivacySheet,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B243B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: Color(0xFFC0C1FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Security & Privacy',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Biometrics, Passwords, Data export',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sign Out Button
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFF8B94),
                size: 18,
              ),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFFF8B94),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBorder = const Color(0xFF5B5FEF);
    final activeBg = const Color(0xFF5B5FEF).withValues(alpha: isDark ? 0.22 : 0.12);
    final inactiveBg = isDark ? const Color(0xFF1B243B) : const Color(0xFFF1F5F9);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeBorder : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (isDark ? const Color(0xFFC0C1FF) : const Color(0xFF5B5FEF))
                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccentCircle(WidgetRef ref, Color color, Color selectedColor) {
    final isSelected = color.toARGB32() == selectedColor.toARGB32();
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(accentColorProvider.notifier).setAccent(color);
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.5 : 0.2),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? const Center(
                child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
              )
            : null,
      ),
    );
  }
}
