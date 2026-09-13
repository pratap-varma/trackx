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
  late TextEditingController _groqApiKeyController;
  bool _obscureKey = true;
  bool _obscureGroqKey = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(aiSettingsProvider);
    _apiKeyController = TextEditingController(text: settings.customApiKey);
    _groqApiKeyController = TextEditingController(text: settings.groqApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _groqApiKeyController.dispose();
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

  Future<void> _saveGroqKey() async {
    final key = _groqApiKeyController.text.trim();
    await ref.read(aiSettingsProvider.notifier).setGroqApiKey(key);
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(key.isNotEmpty ? 'Groq API Key saved!' : 'Groq Key cleared.'),
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

  Future<void> _pasteGroqFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _groqApiKeyController.text = data.text!.trim();
      await _saveGroqKey();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final mutedTextColor = context.mutedTextColor;
    final fieldBg = isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9);
    final fieldBorder = isDark ? Colors.white12 : Colors.black12;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'AI Assistant & Key Settings',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.key_rounded,
                            color: Color(0xFF5B5FEF),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Google Gemini API Key',
                            style: TextStyle(
                              color: textColor,
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
                  Text(
                    'Used for attendance portal screenshot scanning, AI readiness calculations, flashcard generation, and study chats.',
                    style: TextStyle(color: subtextColor, fontSize: 11.5, height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  // Text Field
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      hintStyle: TextStyle(color: mutedTextColor, fontSize: 12),
                      filled: true,
                      fillColor: fieldBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: fieldBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: fieldBorder),
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
                              color: mutedTextColor,
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
                          foregroundColor: const Color(0xFF5B5FEF),
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
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF5B5FEF), size: 15),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Get a 100% free personal key at aistudio.google.com',
                            style: TextStyle(color: Color(0xFF5B5FEF), fontSize: 11, fontWeight: FontWeight.w500),
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
                          child: const Icon(Icons.copy_rounded, color: Color(0xFF5B5FEF), size: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // GROQ API Key Card (for attendance screenshot scanner)
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Color(0xFF8B5CF6), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Groq API Key',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'For attendance screenshot scanning (recommended)',
                              style: TextStyle(color: subtextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('FREE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _groqApiKeyController,
                    obscureText: _obscureGroqKey,
                    style: TextStyle(color: textColor, fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'gsk_...',
                      hintStyle: TextStyle(color: mutedTextColor),
                      filled: true,
                      fillColor: fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: fieldBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: fieldBorder),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_obscureGroqKey ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: mutedTextColor, size: 18),
                            onPressed: () => setState(() => _obscureGroqKey = !_obscureGroqKey),
                          ),
                          IconButton(
                            icon: Icon(Icons.paste_rounded, color: mutedTextColor, size: 18),
                            onPressed: _pasteGroqFromClipboard,
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => _saveGroqKey(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _saveGroqKey,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Save Groq Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 15),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Get a free key at console.groq.com — works on college WiFi!',
                            style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: 'https://console.groq.com'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied: https://console.groq.com'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, color: Color(0xFF8B5CF6), size: 14),
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
                title: Text(
                  'Enable AI Assistant',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Allow helper suggestions, breakdowns, and revision schedules.',
                  style: TextStyle(color: subtextColor, fontSize: 11),
                ),
                value: settings.enableAi,
                activeThumbColor: context.accentColor,
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
                  Text(
                    'AI Engine Provider',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose between local private offline intelligence or cloud Gemini.',
                    style: TextStyle(color: subtextColor, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: fieldBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: (settings.provider == 'Offline only' || settings.provider == 'Offline')
                            ? 'Gemini'
                            : (settings.provider == 'Auto' ? 'Gemini' : settings.provider),
                        dropdownColor: context.cardColor,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: mutedTextColor,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Gemini',
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Google Gemini (Live Online AI)',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
                    title: Text(
                      'Save Chat History Locally',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Retain previous chat threads for offline retrieval.',
                      style: TextStyle(color: subtextColor, fontSize: 11),
                    ),
                    value: settings.saveHistory,
                    activeThumbColor: context.accentColor,
                    onChanged: (val) {
                      settingsNotifier.toggleSaveHistory(val);
                    },
                  ),
                  Divider(color: fieldBorder),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Show Context Preview Dialog',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Preview which data modules will be shared before sending queries.',
                      style: TextStyle(color: subtextColor, fontSize: 11),
                    ),
                    value: settings.showConsentPreview,
                    activeThumbColor: context.accentColor,
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
                  Text(
                    'AI Context Sharing Permissions',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select which information TrackX can send to Gemini / Local Fallback.',
                    style: TextStyle(color: subtextColor, fontSize: 11),
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
                                Text(
                                  'Clear Action Logs?',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Are you sure you want to clear automated and suggested action audit records?',
                                  style: TextStyle(
                                    color: subtextColor,
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
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: mutedTextColor),
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
    final textColor = context.textColor;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: textColor, fontSize: 12),
      ),
      value: val,
      activeThumbColor: context.accentColor,
      onChanged: (_) {
        notifier.toggleConsentFlag(flagKey);
      },
    );
  }
}
