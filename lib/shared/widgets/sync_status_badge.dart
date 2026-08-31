import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackx/core/services/sync_service.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  void _showSyncDetailsSheet(BuildContext context, WidgetRef ref, SyncStatusState syncState) {
    HapticFeedback.lightImpact();
    final timeStr = syncState.lastSyncTime != null
        ? DateFormat('hh:mm a, MMM d').format(syncState.lastSyncTime!)
        : 'Never';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (syncState.pendingCount > 0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981))
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    syncState.isSyncing
                        ? Icons.sync_rounded
                        : (syncState.pendingCount > 0
                            ? Icons.cloud_queue_rounded
                            : Icons.cloud_done_rounded),
                    color: syncState.pendingCount > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncState.isSyncing
                          ? 'Synchronizing...'
                          : (syncState.pendingCount > 0
                              ? 'Offline Changes Queued'
                              : 'All Changes Synchronized'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last sync: $timeStr',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            GlassContainer(
              tier: GlassTier.subtle,
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow('Pending Sync Operations', '${syncState.pendingCount}'),
                  const Divider(color: Colors.white10, height: 16),
                  _infoRow('Failed Retries', '${syncState.failedCount}'),
                  const Divider(color: Colors.white10, height: 16),
                  _infoRow('Storage Strategy', 'Offline-First (Hive ➔ Firestore)'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(syncServiceProvider).triggerSync();
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text(
                  'Sync Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);

    // If completely idle with 0 pending changes, hide or show minimal icon
    if (!syncState.isSyncing && syncState.pendingCount == 0 && syncState.lastError == null) {
      return const SizedBox.shrink();
    }

    final isSyncing = syncState.isSyncing;
    final hasPending = syncState.pendingCount > 0;
    final hasError = syncState.lastError != null;

    final Color badgeColor = isSyncing
        ? const Color(0xFF7BD0FF)
        : (hasError
            ? const Color(0xFFEF4444)
            : (hasPending
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981)));

    final String label = isSyncing
        ? 'Syncing...'
        : (hasError
            ? 'Sync issue'
            : '$hasPending queued');

    return GestureDetector(
      onTap: () => _showSyncDetailsSheet(context, ref, syncState),
      child: GlassContainer(
        tier: GlassTier.subtle,
        borderRadius: 20,
        showLightRim: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        borderColor: badgeColor.withValues(alpha: 0.4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
