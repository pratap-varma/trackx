import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/admin/providers/admin_providers.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AdminActivityScreen extends ConsumerWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsOverviewProvider);
    final logsAsync = ref.watch(adminActivityLogsProvider);

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
            'Activity & Telemetry',
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
                ref.invalidate(adminAnalyticsOverviewProvider);
                ref.invalidate(adminActivityLogsProvider);
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            // Feature Breakdown Card
            const Text(
              'FEATURE ENGAGEMENT METRICS',
              style: TextStyle(
                color: Color(0xFF908FA0),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            analyticsAsync.when(
              data: (analytics) {
                final breakdown = analytics.featureUsageBreakdown;
                final totalEvents = breakdown.values.fold(0, (sum, val) => sum + val);

                return GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  borderColor: Colors.white.withValues(alpha: 0.1),
                  child: Column(
                    children: [
                      _buildFeatureBar('Attendance Tracking', breakdown['Attendance'] ?? 0, totalEvents, const Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      _buildFeatureBar('AI Assistant & Chat', breakdown['AI Assistant'] ?? 0, totalEvents, const Color(0xFFC0C1FF)),
                      const SizedBox(height: 12),
                      _buildFeatureBar('OCR & Timetable Import', breakdown['OCR & Timetable Import'] ?? 0, totalEvents, const Color(0xFFF59E0B)),
                      const SizedBox(height: 12),
                      _buildFeatureBar('Planner, Tasks & Exams', breakdown['Planner & Tasks'] ?? 0, totalEvents, const Color(0xFF7BD0FF)),
                      const SizedBox(height: 12),
                      _buildFeatureBar('Flashcards & Notes', breakdown['Flashcards & Notes'] ?? 0, totalEvents, const Color(0xFFEC4899)),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: AppTheme.accentPurple),
                ),
              ),
              error: (e, _) => GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading stats: $e', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
            const SizedBox(height: 24),

            // Live Audit Log Stream
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'REAL-TIME AUDIT LOGS',
                  style: TextStyle(
                    color: Color(0xFF908FA0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Last 50 events',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),

            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: const Center(
                      child: Text(
                        'No telemetry logs recorded yet.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  );
                }

                return Column(
                  children: logs.map((log) {
                    final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
                    final timeStr = DateFormat('MMM dd, hh:mm:ss a').format(date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getEventColor(log.event).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getEventIcon(log.event),
                              color: _getEventColor(log.event),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'UID: ${log.uid}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: AppTheme.accentPurple),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBar(String label, int count, int total, Color color) {
    final double pct = total > 0 ? (count / total) : 0.0;
    final int pctInt = (pct * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              '$count actions ($pctInt%)',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total > 0 ? pct : 0.05,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getEventColor(String event) {
    final e = event.toLowerCase();
    if (e.contains('attendance')) return const Color(0xFF10B981);
    if (e.contains('ai')) return const Color(0xFFC0C1FF);
    if (e.contains('ocr') || e.contains('import')) return const Color(0xFFF59E0B);
    if (e.contains('login') || e.contains('auth')) return const Color(0xFF5B5FEF);
    return const Color(0xFF7BD0FF);
  }

  IconData _getEventIcon(String event) {
    final e = event.toLowerCase();
    if (e.contains('attendance')) return Icons.fact_check_rounded;
    if (e.contains('ai')) return Icons.auto_awesome_rounded;
    if (e.contains('ocr') || e.contains('import')) return Icons.document_scanner_rounded;
    if (e.contains('login') || e.contains('auth')) return Icons.login_rounded;
    return Icons.radio_button_checked_rounded;
  }
}
