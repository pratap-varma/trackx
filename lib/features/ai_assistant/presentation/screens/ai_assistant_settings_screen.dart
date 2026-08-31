import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class AiAssistantSettingsScreen extends ConsumerStatefulWidget {
  const AiAssistantSettingsScreen({super.key});

  @override
  ConsumerState<AiAssistantSettingsScreen> createState() =>
      _AiAssistantSettingsScreenState();
}

class _AiAssistantSettingsScreenState
    extends ConsumerState<AiAssistantSettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final initialKey = ref.read(aiSettingsProvider).customApiKey;
    _apiKeyController = TextEditingController(text: initialKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final key = _apiKeyController.text.trim();
    await ref.read(aiSettingsProvider.notifier).setCustomApiKey(key);
    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(
                key.isNotEmpty
                    ? 'Gemini API Key saved successfully!'
                    : 'API Key cleared. Using local offline fallback.',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF131A2B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _apiKeyController.text = data.text!.trim();
      await _saveKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);
    final actionHistoryRepo = ref.watch(aiActionHistoryRepositoryProvider);
    final hasKey = settings.customApiKey.trim().isNotEmpty;

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
            'AI Assistant & Key Settings',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // API Key Card (Top Priority)
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderColor: hasKey
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : const Color(0xFF5B5FEF).withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.key_rounded,
                            color: Color(0xFFC0C1FF),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Google Gemini API Key',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasKey
                              ? const Color(0xFF10B981).withValues(alpha: 0.18)
                              : const Color(0xFFEF4444).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: hasKey
                                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                : const Color(0xFFEF4444).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          hasKey ? 'ACTIVE' : 'MISSING',
                          style: TextStyle(
                            color: hasKey ? const Color(0xFF10B981) : const Color(0xFFFF8B94),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Used for attendance portal screenshot scanning, AI readiness calculations, flashcard generation, and study chats.',
                    style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  // Text Field
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF131A2B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        borderSide: const BorderSide(color: Color(0xFF5B5FEF)),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: Colors.white60,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscureKey = !_obscureKey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actions Row: Paste & Save
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC0C1FF),
                          side: const BorderSide(color: Color(0xFF5B5FEF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.content_paste_rounded, size: 15),
                        label: const Text('Paste Key', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B5FEF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: _saveKey,
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Save API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Helper Link Info Box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF7BD0FF), size: 15),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Get a 100% free personal key at aistudio.google.com',
                            style: TextStyle(color: Color(0xFF7BD0FF), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: 'https://aistudio.google.com'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied link: https://aistudio.google.com'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, color: Color(0xFF7BD0FF), size: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
