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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Allow helper suggestions, breakdowns, and revision schedules.',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                value: settings.enableAi,
                activeThumbColor: AppTheme.accentPurple,
                onChanged: (val) {
                  settingsNotifier.toggleEnableAi(val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // AI Engine / Provider Selection
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Engine Provider',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose between local private offline intelligence or cloud Gemini.',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ['Auto', 'Offline only', 'Gemini'].contains(
                              settings.provider,
                            )
                            ? settings.provider
                            : 'Auto',
                        dropdownColor: const Color(0xFF131A2B),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Colors.white70,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Auto',
                            child: Text(
                              'Auto (Offline Fallback + Cloud)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Offline only',
                            child: Text(
                              'Offline Engine (No Internet Required)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Gemini',
                            child: Text(
                              'Google Gemini Cloud',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            settingsNotifier.setProvider(val);
                          }
                        },
                      ),
                    ),
                  ),
                  if (settings.provider != 'Offline only') ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Custom Gemini API Key (Optional)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: settings.customApiKey,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Paste GEMINI_API_KEY (or leave blank for offline)',
                        hintStyle: const TextStyle(
                          color: Colors.white30,
                          fontSize: 11.5,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF131A2B),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.accentPurple,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        settingsNotifier.setCustomApiKey(val.trim());
                      },
                    ),
                  ],
                ],
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Retain previous chat threads for offline retrieval.',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    value: settings.saveHistory,
                    activeThumbColor: AppTheme.accentPurple,
                    onChanged: (val) {
                      settingsNotifier.toggleSaveHistory(val);
                    },
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Show Context Preview Dialog',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Preview which data modules will be shared before sending queries.',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    value: settings.showConsentPreview,
                    activeThumbColor: AppTheme.accentPurple,
                    onChanged: (val) {
                      settingsNotifier.toggleShowPreview(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Data Context Consents
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Context Sharing Permissions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select which information TrackX can send to Gemini / Local Fallback.',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  _buildConsentTile(
                    context,
                    'Subject list and target rates',
                    'attendance',
                    settings,
                    settingsNotifier,
                  ),
                  _buildConsentTile(
                    context,
                    'Exam schedules and countdowns',
                    'exams',
                    settings,
                    settingsNotifier,
                  ),
                  _buildConsentTile(
                    context,
                    'Pending assignments and dues',
                    'assignments',
                    settings,
                    settingsNotifier,
                  ),
                  _buildConsentTile(
                    context,
                    'Personal planner and study tasks',
                    'tasks',
                    settings,
                    settingsNotifier,
                  ),
                  _buildConsentTile(
                    context,
                    'Study notes contents (Disabled by default)',
                    'notes',
                    settings,
                    settingsNotifier,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Clear Actions
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: GlassContainer(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Clear Action Logs?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Are you sure you want to clear automated and suggested action audit records?',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.white60),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await actionHistoryRepo.clearHistory();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Action history deleted.'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Clear Action Audit Logs',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
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
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      value: val,
      activeThumbColor: AppTheme.accentPurple,
      onChanged: (_) {
        notifier.toggleConsentFlag(flagKey);
      },
    );
  }
}
