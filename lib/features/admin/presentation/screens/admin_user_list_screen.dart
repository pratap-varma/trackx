import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/admin/providers/admin_providers.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class AdminUserListScreen extends ConsumerStatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  ConsumerState<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends ConsumerState<AdminUserListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersListProvider);
    final activeFilter = ref.watch(adminUsersFilterProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'User Directory',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(adminUsersListProvider);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar & Filter Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  GlassTextField(
                    controller: _searchController,
                    labelText: 'Search Directory',
                    hintText: 'Search by name, email, or department...',
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(adminUsersSearchProvider.notifier).state = '';
                            },
                          )
                        : null,
                    onChanged: (val) {
                      ref.read(adminUsersSearchProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('All', activeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', activeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Suspended', activeFilter),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Users List View
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No student accounts found',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(context, user);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentPurple),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Failed to load user directory: $e',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String current) {
    final isSelected = current == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(adminUsersFilterProvider.notifier).state = label;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5B5FEF)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5B5FEF)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, dynamic user) {
    final signupDate = user.createdTimestamp > 0
        ? DateFormat('MMM dd, yyyy').format(
            DateTime.fromMillisecondsSinceEpoch(user.createdTimestamp),
          )
        : 'Unknown';

    final lastActiveStr = user.lastActiveTimestamp != null && user.lastActiveTimestamp > 0
        ? DateFormat('MMM dd, hh:mm a').format(
            DateTime.fromMillisecondsSinceEpoch(user.lastActiveTimestamp!),
          )
        : 'Never';

    final isSuspended = user.isSuspended;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/admin/users/${user.uid}');
        },
        borderRadius: BorderRadius.circular(18),
        child: GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          borderColor: isSuspended
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: isSuspended
                    ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                    : const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                child: Text(
                  user.name.isNotEmpty
                      ? user.name.substring(0, 1).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: isSuspended
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFC0C1FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name.isNotEmpty ? user.name : 'Student Account',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSuspended
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSuspended
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                  : const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            isSuspended ? 'SUSPENDED' : 'ACTIVE',
                            style: TextStyle(
                              color: isSuspended
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined: $signupDate • Active: $lastActiveStr',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
