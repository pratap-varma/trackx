import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/admin/domain/models/admin_models.dart';
import 'package:trackx/features/admin/providers/admin_providers.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String uid;

  const AdminUserDetailScreen({super.key, required this.uid});

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _isUpdatingSuspension = false;
  String _taskFilter = 'All'; // 'All', 'Completed', 'Pending'

  Future<void> _toggleSuspension(bool currentStatus) async {
    final targetStatus = !currentStatus;
    final actionText = targetStatus ? 'Suspend' : 'Reactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$actionText Account?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          targetStatus
              ? 'Suspending this account will immediately block the student from signing in and accessing their dashboard.'
              : 'Reactivating this account will restore the student’s ability to sign in and use TrackX.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: targetStatus ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isUpdatingSuspension = true);
      HapticFeedback.heavyImpact();

      try {
        await ref.read(adminRepositoryProvider).toggleUserSuspension(widget.uid, targetStatus);
        ref.invalidate(adminUserDetailProvider(widget.uid));
        ref.invalidate(adminUsersListProvider);
        ref.invalidate(adminAnalyticsOverviewProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account successfully ${targetStatus ? 'suspended' : 'reactivated'}.'),
              backgroundColor: targetStatus ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdatingSuspension = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminUserDetailProvider(widget.uid));

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
            'User Inspection',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: () => ref.invalidate(adminUserDetailProvider(widget.uid)),
            ),
          ],
        ),
        body: detailAsync.when(
          data: (detail) {
            if (detail == null) {
              return const Center(
                child: Text('User profile not found.', style: TextStyle(color: Colors.white70)),
              );
            }

            final user = detail.summary;
            final isSuspended = user.isSuspended;
            final signupDate = user.createdTimestamp > 0
                ? DateFormat('MMM dd, yyyy').format(
                    DateTime.fromMillisecondsSinceEpoch(user.createdTimestamp),
                  )
                : 'Unknown';

            final lastActiveStr = user.lastActiveTimestamp != null && user.lastActiveTimestamp! > 0
                ? DateFormat('MMM dd, yyyy - hh:mm a').format(
                    DateTime.fromMillisecondsSinceEpoch(user.lastActiveTimestamp!),
                  )
                : 'No recent activity recorded';

            final allTasks = detail.tasks;
            final completedTasks = allTasks.where((t) => t.isCompleted).toList();
            final pendingTasks = allTasks.where((t) => !t.isCompleted).toList();

            List<AdminUserTask> displayedTasks = allTasks;
            if (_taskFilter == 'Completed') {
              displayedTasks = completedTasks;
            } else if (_taskFilter == 'Pending') {
              displayedTasks = pendingTasks;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
              children: [
                // Header Profile Hero Card
                GlassContainer(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(20),
                  borderColor: isSuspended
                      ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                      : const Color(0xFF5B5FEF).withValues(alpha: 0.3),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
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
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name.isNotEmpty ? user.name : 'Unnamed Student',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'UID: ${user.uid}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailPill('Department', user.branch.isNotEmpty ? user.branch : 'General'),
                          _buildDetailPill('Semester', 'Sem ${user.semester}'),
                          _buildDetailPill('Registered', signupDate),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Account Status & Suspension Controls
                GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  borderColor: isSuspended
                      ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Access Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSuspended
                                ? 'Account is currently SUSPENDED.'
                                : 'Account is active and verified.',
                            style: TextStyle(
                              color: isSuspended ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _isUpdatingSuspension
                            ? null
                            : () => _toggleSuspension(isSuspended),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSuspended
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isUpdatingSuspension
                              ? 'Updating...'
                              : (isSuspended ? 'Reactivate' : 'Suspend'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Feature Usage & Telemetry Stats
                const Text(
                  'FEATURE USAGE BREAKDOWN',
                  style: TextStyle(
                    color: Color(0xFF908FA0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _buildStatGridTile('Attendance Logs', '${detail.attendanceCount}', Icons.fact_check_rounded, const Color(0xFF10B981)),
                    _buildStatGridTile('Enrolled Courses', '${detail.subjectsCount}', Icons.subject_rounded, const Color(0xFF5B5FEF)),
                    _buildStatGridTile('Planner Tasks', '${detail.tasksCount}', Icons.check_circle_outline_rounded, const Color(0xFF7BD0FF)),
                    _buildStatGridTile('Scheduled Exams', '${detail.examsCount}', Icons.event_note_rounded, const Color(0xFFF59E0B)),
                    _buildStatGridTile('Study Notes', '${detail.notesCount}', Icons.menu_book_rounded, const Color(0xFFEC4899)),
                    _buildStatGridTile('Flashcard Decks', '${detail.flashcardDecksCount}', Icons.style_rounded, const Color(0xFF8B5CF6)),
                    _buildStatGridTile('AI Assistant Prompts', '${detail.aiQueriesCount}', Icons.auto_awesome_rounded, const Color(0xFFC0C1FF)),
                    _buildStatGridTile('OCR Scans', '${detail.ocrScansCount}', Icons.document_scanner_rounded, const Color(0xFFFF8B94)),
                  ],
                ),
                const SizedBox(height: 22),

                // 6 AI Features Granular Breakdown
                const Text(
                  '6 AI FEATURES USAGE (PER USER)',
                  style: TextStyle(
                    color: Color(0xFF908FA0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  borderColor: const Color(0xFF5B5FEF).withValues(alpha: 0.25),
                  child: Column(
                    children: [
                      _buildAiFeatureRow('Timetable Grid OCR', '${detail.aiFeatureBreakdown['Timetable Grid OCR'] ?? 0}x', Icons.table_chart_rounded, const Color(0xFF10B981)),
                      const Divider(color: Colors.white10, height: 16),
                      _buildAiFeatureRow('Exam Datesheet OCR', '${detail.aiFeatureBreakdown['Exam Datesheet OCR'] ?? 0}x', Icons.event_note_rounded, const Color(0xFFFF8B94)),
                      const Divider(color: Colors.white10, height: 16),
                      _buildAiFeatureRow('Attendance Screenshot OCR', '${detail.aiFeatureBreakdown['Attendance Screenshot OCR'] ?? 0}x', Icons.fact_check_rounded, const Color(0xFF7BD0FF)),
                      const Divider(color: Colors.white10, height: 16),
                      _buildAiFeatureRow('Multimodal Document Analyzer', '${detail.aiFeatureBreakdown['Document Analyzer'] ?? 0}x', Icons.picture_as_pdf_rounded, const Color(0xFFF59E0B)),
                      const Divider(color: Colors.white10, height: 16),
                      _buildAiFeatureRow('AI Flashcard Generator', '${detail.aiFeatureBreakdown['AI Flashcard Generator'] ?? 0}x', Icons.style_rounded, const Color(0xFF8B5CF6)),
                      const Divider(color: Colors.white10, height: 16),
                      _buildAiFeatureRow('Academic Assistant Chat', '${detail.aiFeatureBreakdown['Academic Assistant Chat'] ?? 0}x', Icons.auto_awesome_rounded, const Color(0xFFC0C1FF)),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // USER TASKS & TO-DOS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TASKS & TO-DOS CREATED/DONE',
                      style: TextStyle(
                        color: Color(0xFF908FA0),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${completedTasks.length}/${allTasks.length} Completed',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Task Filter Chips
                Row(
                  children: [
                    _buildTaskFilterChip('All (${allTasks.length})', 'All'),
                    const SizedBox(width: 8),
                    _buildTaskFilterChip('Done (${completedTasks.length})', 'Completed'),
                    const SizedBox(width: 8),
                    _buildTaskFilterChip('Pending (${pendingTasks.length})', 'Pending'),
                  ],
                ),
                const SizedBox(height: 10),

                if (displayedTasks.isEmpty)
                  GlassContainer(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: Text(
                        _taskFilter == 'All'
                            ? 'No tasks recorded for this user yet.'
                            : 'No $_taskFilter tasks found.',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  )
                else
                  Column(
                    children: displayedTasks.map((t) => _buildTaskCard(t)).toList(),
                  ),

                const SizedBox(height: 26),

                // Full User Activity Timeline
                const Text(
                  'ALL ACTIONS DONE IN APP',
                  style: TextStyle(
                    color: Color(0xFF908FA0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last session timestamp: $lastActiveStr',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 10),

                if (detail.recentLogs.isEmpty)
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Text(
                        'No specific activity logs recorded for this student yet.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  )
                else
                  Column(
                    children: detail.recentLogs.map((log) {
                      final timeStr = DateFormat('MMM dd, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(log.timestamp),
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF7BD0FF)),
                                const SizedBox(width: 8),
                                Text(
                                  log.event,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accentPurple),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskFilterChip(String label, String value) {
    final isSelected = _taskFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _taskFilter = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B5FEF) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B5FEF) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(AdminUserTask task) {
    final dueStr = DateFormat('MMM dd, yyyy').format(task.dueDate);
    final isDone = task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFF10B981).withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isDone ? const Color(0xFF10B981) : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: isDone ? Colors.white70 : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDone ? 'DONE' : 'PENDING',
                        style: TextStyle(
                          color: isDone ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B5FEF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.category,
                        style: const TextStyle(color: Color(0xFFC0C1FF), fontSize: 9),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Due: $dueStr',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPill(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGridTile(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeatureRow(String title, String count, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
