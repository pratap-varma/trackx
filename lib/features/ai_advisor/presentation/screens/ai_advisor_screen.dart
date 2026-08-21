import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/ai_advisor/domain/models/ai_models.dart';
import 'package:trackx/features/ai_advisor/presentation/screens/ai_privacy_screen.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';

import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';

final aiProviderPreference = StateProvider<String>((ref) => 'Auto');

final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<AiMessage>>((ref) {
      return ChatMessagesNotifier(ref);
    });

class ChatMessagesNotifier extends StateNotifier<List<AiMessage>> {
  final Ref _ref;

  ChatMessagesNotifier(this._ref) : super([]) {
    // Add default initial greeting
    final profile = _ref.read(authRepositoryProvider).userProfile;
    final name = profile?.name.isNotEmpty == true ? ', ${profile!.name}' : '';
    state = [
      AiMessage(
        id: 'init',
        conversationId: 'c1',
        sender: 'ai',
        content:
            'Hello$name! I am your TrackX AI Advisor. How can I help you optimize your studies and attendance today?',
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

    final stats = _ref.read(statsProvider);
    final subjects = _ref.read(subjectRepositoryProvider);
    final exams = _ref.read(examsProvider);
    final tasks = _ref.read(tasksProvider);

    // Generate responsive response contextually
    Future.delayed(const Duration(milliseconds: 800), () {
      String reply = '';
      List<StructuredAction> actions = [];

      final lower = content.toLowerCase();

      if (subjects.isEmpty) {
        reply =
            'No attendance data yet. Add your subjects and attendance to get personalized insights.';
      } else if (lower.contains('miss') ||
          lower.contains('bunk') ||
          lower.contains('attendance')) {
        final lowSubjects = stats.allSubjectStats
            .where((s) => s.percentage < s.target)
            .toList();
        if (lowSubjects.isNotEmpty) {
          final worst = lowSubjects.first;
          reply =
              'Your attendance in ${worst.subject.name} is currently ${worst.percentage.toStringAsFixed(0)}% (Target: ${worst.target.toStringAsFixed(0)}%). Missing another class will reduce it further. You need ${worst.requiredRecovery} classes to recover.';
          actions = [
            StructuredAction(
              type: 'OpenSubject',
              parameters: {'subjectId': worst.subject.id},
            ),
          ];
        } else {
          final firstSub = stats.allSubjectStats.first;
          reply =
              'All your enrolled subjects are currently above target! In ${firstSub.subject.name}, your attendance is ${firstSub.percentage.toStringAsFixed(0)}% with ${firstSub.safeBunks} safe skips available.';
          actions = [
            StructuredAction(
              type: 'OpenForecast',
              parameters: {'subjectId': firstSub.subject.id},
            ),
          ];
        }
      } else if (lower.contains('study') ||
          lower.contains('week') ||
          lower.contains('plan')) {
        final subNames = subjects.take(2).map((s) => s.name).toList();
        if (subNames.length >= 2) {
          reply =
              'Here is your generated study plan draft:\n• Friday: 2 hrs ${subNames[0]} revision\n• Saturday: 1.5 hrs ${subNames[1]} preparation.';
        } else if (subNames.isNotEmpty) {
          reply =
              'Here is your generated study plan draft:\n• Friday: 2 hrs ${subNames[0]} revision.';
        } else {
          reply =
              'No subjects added yet. Add subjects to generate an optimized study plan.';
        }
        actions = [
          StructuredAction(
            type: 'CreateStudySessionDraft',
            parameters: {'hours': 2},
          ),
        ];
      } else if (lower.contains('exam')) {
        if (exams.isNotEmpty) {
          final nextExam = exams.first;
          reply =
              'Your upcoming exam is ${nextExam.title}. Current preparation progress is ${nextExam.preparationProgress.toStringAsFixed(0)}%. I recommend reviewing the key formula sheets and practice assignments.';
        } else {
          reply =
              'No upcoming exams found in your planner. Add your exam dates in the Planner to track revision timelines.';
        }
      } else {
        if (tasks.isNotEmpty) {
          final pending = tasks.where((t) => !t.isCompleted).toList();
          if (pending.isNotEmpty) {
            reply =
                'I recommend completing your pending task "${pending.first.title}" first to stay on track.';
          } else {
            reply =
                'All your current tasks are completed! Keep up the great work maintaining your study goals.';
          }
        } else {
          reply =
              'Your attendance and study routines are synchronized. How else can I assist your academic planning?';
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
