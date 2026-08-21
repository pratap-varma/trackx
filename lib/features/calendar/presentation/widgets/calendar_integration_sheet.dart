import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/calendar/providers/calendar_provider.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class CalendarIntegrationSheet extends ConsumerStatefulWidget {
  const CalendarIntegrationSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CalendarIntegrationSheet(),
    );
  }

  @override
  ConsumerState<CalendarIntegrationSheet> createState() =>
      _CalendarIntegrationSheetState();
}

class _CalendarIntegrationSheetState
    extends ConsumerState<CalendarIntegrationSheet> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _handleConnect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final success = await ref
        .read(calendarRepositoryProvider.notifier)
        .connectAndSync();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? 'Connected! Synced personal & holiday calendars.'
            : 'Permission denied or Google Calendar access unavailable.';
      });
    }
  }

  Future<void> _handleDisconnect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    await ref.read(calendarRepositoryProvider.notifier).disconnect();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Google Calendar disconnected.';
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final success = await ref
        .read(calendarRepositoryProvider.notifier)
        .refreshEvents();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? 'Refreshed latest calendar events.'
            : 'Could not refresh. Saved events remain accessible.';
      });
    }
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Not synced yet';
    final now = DateTime.now();
    final isToday =
        now.year == lastSync.year &&
        now.month == lastSync.month &&
        now.day == lastSync.day;
    final timeStr = DateFormat('h:mm a').format(lastSync);
    return isToday
        ? 'Today, $timeStr'
        : '${DateFormat('MMM d').format(lastSync)}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(isCalendarConnectedProvider);
    final events = ref.watch(calendarRepositoryProvider);
    final userCalendars = ref.watch(userCalendarsListProvider);
    final lastSyncTime = ref.watch(calendarLastSyncTimeProvider);
    final region = ref.watch(calendarRegionProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
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
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF4285F4),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Calendar Integration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? const Color(0xFF10B981)
                                    : Colors.white38,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected
                                  ? 'Connected • ${events.length} events cached'
                                  : 'Not connected',
                              style: TextStyle(
                                color: isConnected
                                    ? const Color(0xFF10B981)
                                    : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const Text(
                  'TrackX requests read-only access to display your personal calendar events, public holidays, and festivals in your Planner. TrackX will never create, modify, or delete your events.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              if (isConnected) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACTIVE CALENDARS',
                      style: TextStyle(
                        color: Color(0xFF908FA0),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Last synced: ${_formatLastSync(lastSyncTime)}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (userCalendars.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Holidays in ${region == 'indian' ? 'India' : region} (Default)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...userCalendars.map((cal) {
                    final icon = cal.isHolidayCalendar
                        ? Icons.celebration_rounded
                        : Icons.event_note_rounded;
                    final iconColor = cal.isHolidayCalendar
                        ? AppTheme.accentOrange
                        : const Color(0xFF4285F4);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cal.isSelected
                              ? iconColor.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: iconColor, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cal.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (cal.isPrimary)
                                  const Text(
                                    'Primary Google Account',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: cal.isSelected,
                            activeColor: const Color(0xFF5B5FEF),
                            onChanged: (v) {
                              ref
                                  .read(calendarRepositoryProvider.notifier)
                                  .toggleCalendarSelection(cal.id);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(
                      color: AppTheme.accentPurple,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: AppTheme.accentPurple,
                    ),
                  ),
                )
              else if (!isConnected)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _handleConnect,
                    icon: const Icon(Icons.sync_rounded, size: 20),
                    label: const Text(
                      'Connect Google Calendar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _handleDisconnect,
                        icon: const Icon(Icons.link_off_rounded, size: 18),
                        label: const Text('Disconnect'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B5FEF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _handleRefresh,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Refresh'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
