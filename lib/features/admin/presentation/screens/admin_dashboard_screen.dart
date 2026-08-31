import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/admin/providers/admin_providers.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsOverviewProvider);
    final authState = ref.watch(adminAuthStateProvider);
    final admin = authState.admin;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Admin Dashboard',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconTheme: IconThemeData(color: context.textColor),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: context.subtextColor),
              tooltip: 'Refresh Metrics',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(adminAnalyticsOverviewProvider);
                ref.invalidate(adminUsersListProvider);
                ref.invalidate(adminActivityLogsProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Sign Out Admin',
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await ref.read(adminAuthStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/admin/login');
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminAnalyticsOverviewProvider);
            ref.invalidate(adminUsersListProvider);
            ref.invalidate(adminActivityLogsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // Admin Header Card
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(18),
                borderColor: const Color(0xFF5B5FEF).withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5B5FEF),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator Control Center',
                            style: TextStyle(
                              color: context.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            admin?.email ?? 'admin@trackx.app',
                            style: TextStyle(
                              color: context.mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // KPI Metrics Grid
              analyticsAsync.when(
                data: (analytics) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context: context,
                            title: 'Total Users',
                            value: '${analytics.totalUsers}',
                            subtitle: '${analytics.suspendedUsersCount} suspended',
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF7BD0FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context: context,
                            title: 'Active Today',
                            value: '${analytics.activeUsersToday}',
                            subtitle: '${analytics.activeUsersThisWeek} this week',
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context: context,
                            title: 'AI Queries',
                            value: '${analytics.totalAiQueries}',
                            subtitle: 'Gemini assistant requests',
                            icon: Icons.auto_awesome_rounded,
                            color: const Color(0xFFC0C1FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context: context,
                            title: 'OCR Scans',
                            value: '${analytics.totalOcrScans}',
                            subtitle: 'Timetables & attendance',
                            icon: Icons.document_scanner_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
                ),
                error: (e, _) => GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading metrics: $e',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Quick Actions Header
              Text(
                'MANAGEMENT MODULES',
                style: TextStyle(
                  color: context.mutedTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Module Cards
              _buildNavigationCard(
                context: context,
                title: 'User Directory & Management',
                subtitle: 'View, search, inspect usage profiles, and suspend/reactivate student accounts.',
                icon: Icons.manage_accounts_rounded,
                color: const Color(0xFF5B5FEF),
                route: '/admin/users',
              ),
              const SizedBox(height: 12),

              _buildNavigationCard(
                context: context,
                title: 'Feature Analytics & Live Activity',
                subtitle: 'Breakdown of feature engagement (Attendance, Planner, AI, OCR) and real-time logs.',
                icon: Icons.insights_rounded,
                color: const Color(0xFF10B981),
                route: '/admin/activity',
              ),
              const SizedBox(height: 24),

              // Live Activity Preview Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT AUDIT LOGS',
                    style: TextStyle(
                      color: context.mutedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/admin/activity'),
                    child: const Text(
                      'View All',
                      style: TextStyle(color: Color(0xFF7BD0FF), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Activity Log Stream Preview
              Consumer(
                builder: (context, ref, _) {
                  final logsAsync = ref.watch(adminActivityLogsProvider);
                  return logsAsync.when(
                    data: (logs) {
                      if (logs.isEmpty) {
                        return GlassContainer(
                          padding: const EdgeInsets.all(18),
                          child: Center(
                            child: Text(
                              'No recent activity logs recorded yet.',
                              style: TextStyle(color: context.mutedTextColor, fontSize: 12),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: logs.take(4).map((log) => _buildLogTile(context, log)).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: AppTheme.accentPurple),
                      ),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: context.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: context.mutedTextColor,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(18),
        borderColor: context.subtleBorderColor,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.mutedTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(BuildContext context, dynamic log) {
    final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final timeStr = DateFormat('MMM dd, hh:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.subtleBorderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF7BD0FF).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radio_button_checked_rounded,
              color: Color(0xFF7BD0FF),
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.event,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'User: ${log.uid}',
                  style: TextStyle(
                    color: context.mutedTextColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: context.subtextColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
