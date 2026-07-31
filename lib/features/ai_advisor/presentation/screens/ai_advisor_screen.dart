import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/ai_advisor/domain/models/ai_models.dart';
import 'package:trackx/features/ai_advisor/presentation/screens/ai_privacy_screen.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

final aiProviderPreference = StateProvider<String>((ref) => 'Auto');

final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<AiMessage>>((ref) {
      return ChatMessagesNotifier();
    });

class ChatMessagesNotifier extends StateNotifier<List<AiMessage>> {
  ChatMessagesNotifier() : super([]) {
    // Add default initial greeting
    state = [
      AiMessage(
        id: 'init',
        conversationId: 'c1',
        sender: 'ai',
        content:
            'Hello! I am your TrackX AI Advisor. How can I help you optimize your studies and attendance today?',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
  }

  void sendMessage(String content, String provider) {
    final userMsg = AiMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}-user',
      conversationId: 'c1',
      sender: 'user',
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    state = [...state, userMsg];

    // Generate responsive response contextually
    Future.delayed(const Duration(milliseconds: 1200), () {
      String reply = '';
      List<StructuredAction> actions = [];

      if (provider == 'Offline only') {
        reply =
            '[Offline Insight] Based on your offline timetable logs, DBMS requires attendance in the next 2 classes to hit your 75% target.';
        actions = [
          StructuredAction(
            type: 'OpenSubject',
            parameters: {'subjectId': 'dbms'},
          ),
        ];
      } else {
        if (content.toLowerCase().contains('miss')) {
          reply =
              'Missing tomorrow\'s class keeps your DBMS attendance at 76%. However, it leaves you with a narrow 1% margin above your target.';
          actions = [
            StructuredAction(
              type: 'OpenForecast',
              parameters: {'subjectId': 'dbms'},
            ),
          ];
        } else if (content.toLowerCase().contains('study') ||
            content.toLowerCase().contains('week')) {
          reply =
              'Here is your generated study plan draft: \n• Friday: 2 hrs DBMS revision\n• Saturday: 1.5 hrs DAA preparation.';
          actions = [
            StructuredAction(
              type: 'CreateStudySessionDraft',
              parameters: {'hours': 2},
            ),
          ];
        } else {
          reply =
              'I recommend completing your DBMS assignment due tomorrow first, followed by your DAA homework prep.';
        }
      }

      final aiMsg = AiMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-ai',
        conversationId: 'c1',
        sender: 'ai',
        content: reply,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        actions: actions,
      );

      state = [...state, aiMsg];
    });
  }

  void clearHistory() {
    state = [];
  }
}

class AiAdvisorScreen extends ConsumerStatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  ConsumerState<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends ConsumerState<AiAdvisorScreen> {
  final TextEditingController _msgController = TextEditingController();

  final List<String> _suggestedPrompts = [
    'Can I miss tomorrow’s class?',
    'Plan my study week',
    'Which subject needs attention?',
    'Prepare me for my next exam',
  ];

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final selectedProvider = ref.watch(aiProviderPreference);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'AI Advisor',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiPrivacyScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                ref.read(chatMessagesProvider.notifier).clearHistory();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Provider selector banner
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: GlassContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI Provider:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    DropdownButton<String>(
                      dropdownColor: Colors.purple.shade900,
                      value: selectedProvider,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: ['Auto', 'Gemini', 'OpenAI', 'Offline only'].map((
                        provider,
                      ) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(aiProviderPreference.notifier).state = val;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Chat Messages area
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isUser = msg.sender == 'user';

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            if (msg.actions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: msg.actions.map((act) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white10,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Triggered Action: ${act.type}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      act.type,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
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
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: _suggestedPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      backgroundColor: Colors.white10,
                      label: Text(
                        prompt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(chatMessagesProvider.notifier)
                            .sendMessage(prompt, selectedProvider);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Message Composer area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _msgController,
                      labelText: 'Message',
                      hintText: 'Ask academic advisor...',
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () {
                      final txt = _msgController.text.trim();
                      if (txt.isNotEmpty) {
                        ref
                            .read(chatMessagesProvider.notifier)
                            .sendMessage(txt, selectedProvider);
                        _msgController.clear();
                      }
                    },
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
