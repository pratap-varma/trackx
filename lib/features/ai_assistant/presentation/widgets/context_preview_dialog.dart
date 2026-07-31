import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';

class ContextPreviewDialog extends ConsumerWidget {
  final VoidCallback onProceed;

  const ContextPreviewDialog({super.key, required this.onProceed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);

    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: GlassContainer(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Context Consent Preview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'TrackX will include the following local records to answer your query:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildConsentTile('Attendance details', 'attendance', aiSettings.consentFlags, settingsNotifier),
            _buildConsentTile('Timetable log', 'timetable', aiSettings.consentFlags, settingsNotifier),
            _buildConsentTile('Planner tasks list', 'tasks', aiSettings.consentFlags, settingsNotifier),
            _buildConsentTile('Upcoming assignments', 'assignments', aiSettings.consentFlags, settingsNotifier),
            _buildConsentTile('Upcoming exams list', 'exams', aiSettings.consentFlags, settingsNotifier),
            _buildConsentTile('CGPA progress details', 'cgpa', aiSettings.consentFlags, settingsNotifier),
            _buildConsentTile('Note summaries (Disabled by default)', 'notes', aiSettings.consentFlags, settingsNotifier),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onProceed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: !aiSettings.showConsentPreview,
                  onChanged: (val) {
                    if (val != null) {
                      settingsNotifier.toggleShowPreview(!val);
                    }
                  },
                ),
                const Expanded(
                  child: Text(
                    'Don\'t show this preview again',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentTile(
    String label,
    String flagKey,
    Map<String, bool> flags,
    AiSettingsNotifier notifier,
  ) {
    final value = flags[flagKey] ?? false;
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (_) {
            notifier.toggleConsentFlag(flagKey);
          },
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: value ? Colors.white : Colors.white38,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
