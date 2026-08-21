import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/ai_advisor/domain/models/ai_models.dart'
    hide AiRequest;
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_context_builder.dart';
import 'package:trackx/features/ai_assistant/data/services/gemini_provider.dart';
import 'package:trackx/features/ai_assistant/data/services/offline_fallback_provider.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';

class AiChatNotifier extends StateNotifier<List<AiMessage>> {
  final Ref _ref;
  final String _conversationId;

  AiChatNotifier(this._ref, this._conversationId) : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    final repo = _ref.read(aiConversationRepositoryProvider);
    final messages = repo.getMessages(_conversationId);
    if (messages.isEmpty) {
      state = [
        AiMessage(
          id: 'init-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: _conversationId,
          sender: 'ai',
          content:
              'Hello! I am your TrackX AI Academic Assistant. How can I help you optimize your studies and attendance today?',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          actions: const [],
        ),
      ];
    } else {
      state = messages;
    }
  }

  Future<void> sendMessage(String userMessage) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final userMsg = AiMessage(
      id: 'msg-$nowMs-user',
      conversationId: _conversationId,
      sender: 'user',
      content: userMessage,
      timestamp: nowMs,
      actions: const [],
    );

    state = [...state, userMsg];

    final settings = _ref.read(aiSettingsProvider);
    final usageNotifier = _ref.read(aiUsageProvider.notifier);
    final usageSummary = _ref.read(aiUsageProvider);

    // Save user message to database
    final repo = _ref.read(aiConversationRepositoryProvider);
    await repo.saveMessages(_conversationId, state);

    // Verify if AI is disabled
    if (!settings.enableAi) {
      _addErrorMessage(
        'AI Assistant features are currently disabled. Please enable them in Privacy settings.',
      );
      return;
    }

    // Verify rate limit
    if (usageSummary.requestsToday >= usageSummary.maxDailyRequests) {
      _addErrorMessage(
        'You have reached your daily limit of ${usageSummary.maxDailyRequests} requests. Please retry tomorrow.',
      );
      return;
    }

    // Setup fallback or Gemini provider
    final bool useOffline =
        settings.provider == 'Offline only' || settings.provider == 'Offline';
    final provider = useOffline
        ? OfflineFallbackProvider()
        : GeminiAiProvider(overrideApiKey: settings.customApiKey);

    // Context preparation
    final authState = _ref.read(authRepositoryProvider);
    final profile = authState.userProfile;
    if (profile == null) {
      _addErrorMessage('User profile is not loaded.');
      return;
    }

    // Attempt to determine subject reference from keyword
    String? subjectFilterId;
    final subjects = _ref.read(subjectRepositoryProvider);
    for (final s in subjects) {
      if (userMessage.toLowerCase().contains(s.name.toLowerCase()) ||
          (s.code != null &&
              userMessage.toLowerCase().contains(s.code!.toLowerCase()))) {
        subjectFilterId = s.id;
        break;
      }
    }

    // Build context
    final aiContext = AiContextBuilder.build(
      profile: profile,
      semesters: _ref.read(semesterRepositoryProvider),
      subjects: subjects,
      attendance: _ref.read(attendanceRepositoryProvider),
      tasks: _ref.read(tasksProvider),
      assignments: _ref.read(assignmentsProvider),
      exams: _ref.read(examsProvider),
      timetable: _ref.read(timetableRepositoryProvider),
      consentFlags: settings.consentFlags,
      subjectFilterId: subjectFilterId,
    );

    // Map feature type from keywords
    AiFeatureType featureType = AiFeatureType.generalChat;
    if (userMessage.toLowerCase().contains('miss') ||
        userMessage.toLowerCase().contains('attendance')) {
      featureType = AiFeatureType.attendanceExplanation;
    } else if (userMessage.toLowerCase().contains('study plan') ||
        userMessage.toLowerCase().contains('schedule')) {
      featureType = AiFeatureType.studyPlanning;
    } else if (userMessage.toLowerCase().contains('exam') ||
        userMessage.toLowerCase().contains('countdown')) {
      featureType = AiFeatureType.examPreparation;
    } else if (userMessage.toLowerCase().contains('assignment') ||
        userMessage.toLowerCase().contains('breakdown')) {
      featureType = AiFeatureType.assignmentBreakdown;
    }

    final request = AiRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      userId: profile.id,
      featureType: featureType,
      userPrompt: userMessage,
      context: aiContext.toMap(),
      conversationId: _conversationId,
      modelId: useOffline ? 'offline' : 'gemini-1.5-flash',
      createdAt: DateTime.now(),
    );

    // Invoke generation
    final response = await provider.generate(request);

    if (useOffline) {
      await usageNotifier.incrementOfflineFallback();
    } else {
      await usageNotifier.incrementRequests();
    }

    // Map AiResponse back to AiMessage
    final aiMsg = AiMessage(
      id: response.id,
      conversationId: _conversationId,
      sender: 'ai',
      content: response.text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      actions: response.suggestedActions.map((act) {
        return StructuredAction(type: act.type, parameters: act.parameters);
      }).toList(),
    );

    state = [...state, aiMsg];
    await repo.saveMessages(_conversationId, state);
  }

  void _addErrorMessage(String error) {
    final aiMsg = AiMessage(
      id: 'msg-err-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId,
      sender: 'ai',
      content: '⚠️ $error',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      actions: const [],
    );
    state = [...state, aiMsg];
  }

  Future<void> clearHistory() async {
    state = [];
    final repo = _ref.read(aiConversationRepositoryProvider);
    await repo.deleteConversation(_conversationId);
  }
}

final aiChatMessagesProvider =
    StateNotifierProvider.family<AiChatNotifier, List<AiMessage>, String>((
      ref,
      conversationId,
    ) {
      return AiChatNotifier(ref, conversationId);
    });
