import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/ai_advisor/domain/models/ai_models.dart';
import 'package:trackx/features/ai_assistant/presentation/widgets/context_preview_dialog.dart';
import 'package:trackx/features/ai_assistant/presentation/widgets/action_confirmation_sheet.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_response.dart';
import 'package:trackx/features/ai_assistant/providers/ai_chat_notifier.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/features/ai_assistant/presentation/screens/ai_assistant_settings_screen.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String _conversationId = 'default';

  final List<String> _suggestedPrompts = [
    'Can I miss my next DBMS class?',
    'Create a study plan for DBMS.',
    'Break this assignment into smaller tasks.',
    'Prepare me for my next exam.',
  ];

  void _handleSendMessage(String content) {
    if (content.trim().isEmpty) return;
    final settings = ref.read(aiSettingsProvider);

    if (settings.showConsentPreview) {
      showDialog(
        context: context,
        builder: (context) => ContextPreviewDialog(
          onProceed: () {
            ref.read(aiChatMessagesProvider(_conversationId).notifier).sendMessage(content);
          },
        ),
      );
    } else {
      ref.read(aiChatMessagesProvider(_conversationId).notifier).sendMessage(content);
    }
    _msgController.clear();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatMessagesProvider(_conversationId));
    final settings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);
    final usage = ref.watch(aiUsageProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'AI Assistant',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiAssistantSettingsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.transparent,
                    content: GlassContainer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Clear conversation?',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This will clear all local AI assistant chats for this thread.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
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
                  await ref.read(aiChatMessagesProvider(_conversationId).notifier).clearHistory();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Provider & Usage Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Provider:',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        DropdownButton<String>(
                          dropdownColor: Colors.purple.shade900,
                          value: settings.provider,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          underline: const SizedBox(),
                          items: ['Auto', 'Gemini', 'Offline'].map((p) {
                            return DropdownMenuItem(value: p, child: Text(p));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              settingsNotifier.setProvider(val);
                            }
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Daily Quota Used:',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${usage.requestsToday} / ${usage.maxDailyRequests}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Message History Area
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isUser = msg.sender == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? 'You' : 'TrackX AI',
                              style: TextStyle(
                                color: isUser ? Colors.white60 : AppTheme.accentPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.content,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            ),
                            if (msg.actions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Suggested Actions:',
                                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: msg.actions.map((act) {
                                  return ActionChip(
                                    backgroundColor: Colors.white10,
                                    side: const BorderSide(color: Colors.white24),
                                    label: Text(
                                      act.type == 'CreatePlannerTask'
                                          ? '📅 Create Task'
                                          : (act.type == 'CreateStudySession' ? '📖 Study Slot' : act.type),
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => ActionConfirmationSheet(
                                          action: AiSuggestedAction(
                                            type: act.type,
                                            title: act.type,
                                            parameters: act.parameters,
                                          ),
                                          conversationId: _conversationId,
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Suggestions prompt strip
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: _suggestedPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      backgroundColor: Colors.white10,
                      side: const BorderSide(color: Colors.white24),
                      label: Text(
                        prompt,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      onPressed: () => _handleSendMessage(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Composer Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _msgController,
                      labelText: 'Message AI Assistant...',
                      hintText: 'e.g., Can I miss my class?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: AppTheme.accentPurple,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _handleSendMessage(_msgController.text),
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
}
