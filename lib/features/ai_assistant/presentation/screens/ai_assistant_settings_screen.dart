import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AiAssistantSettingsScreen extends ConsumerWidget {
  const AiAssistantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);
    final actionHistoryRepo = ref.watch(aiActionHistoryRepositoryProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'AI Assistant Settings',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Enable Toggle
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Enable AI Assistant',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Allow helper suggestions, breakdowns, and revision schedules.',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                value: settings.enableAi,
                activeColor: AppTheme.accentPurple,
                onChanged: (val) {
                  settingsNotifier.toggleEnableAi(val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // History Toggles
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Save Chat History Locally',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Retain previous chat threads for offline retrieval.',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    value: settings.saveHistory,
                    activeColor: AppTheme.accentPurple,
                    onChanged: (val) {
                      settingsNotifier.toggleSaveHistory(val);
                    },
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Show Context Preview Dialog',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Preview which data modules will be shared before sending queries.',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    value: settings.showConsentPreview,
                    activeColor: AppTheme.accentPurple,
                    onChanged: (val) {
                      settingsNotifier.toggleShowPreview(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Data Context Consents
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'DATA SHARING CONSENTS',
                style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
              ),
            ),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildConsentTile(context, 'Share Subject Attendance Totals', 'attendance', settings, settingsNotifier),
                  const Divider(color: Colors.white10),
                  _buildConsentTile(context, 'Share Timetable Periods Logs', 'timetable', settings, settingsNotifier),
                  const Divider(color: Colors.white10),
                  _buildConsentTile(context, 'Share Planner Tasks Lists', 'tasks', settings, settingsNotifier),
                  const Divider(color: Colors.white10),
                  _buildConsentTile(context, 'Share Upcoming Assignments Details', 'assignments', settings, settingsNotifier),
                  const Divider(color: Colors.white10),
                  _buildConsentTile(context, 'Share Upcoming Exams Schedules', 'exams', settings, settingsNotifier),
                  const Divider(color: Colors.white10),
                  _buildConsentTile(context, 'Share CGPA & Credits Progress', 'cgpa', settings, settingsNotifier),
                  const Divider(color: Colors.white10),
                  _buildConsentTile(context, 'Share Private Study Notes Content', 'notes', settings, settingsNotifier),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Clear Actions
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.transparent,
                          content: GlassContainer(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Clear Action Audit Logs?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                const Text('This will permanently delete the history of AI suggested and confirmed actions.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (confirm == true) {
                        await actionHistoryRepo.clearHistory();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action history deleted.')));
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Clear Action Audit Logs', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentTile(
    BuildContext context,
    String title,
    String flagKey,
    AiSettingsState settings,
    AiSettingsNotifier notifier,
  ) {
    final val = settings.consentFlags[flagKey] ?? false;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      value: val,
      activeColor: AppTheme.accentPurple,
      onChanged: (_) {
        notifier.toggleConsentFlag(flagKey);
      },
    );
  }
}
