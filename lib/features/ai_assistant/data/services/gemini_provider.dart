import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:trackx/core/config/ai_config.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_provider.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_response.dart';

class GeminiAiProvider implements AiProvider {
  final String? overrideApiKey;

  GeminiAiProvider({this.overrideApiKey});

  String _getApiKey() {
    // 1. User-configured override key (e.g. from Settings screen)
    if (overrideApiKey != null && overrideApiKey!.trim().isNotEmpty) {
      return overrideApiKey!.trim();
    }

    // 2. Compile-time constant passed via `--dart-define=GEMINI_API_KEY=your_key`
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey.trim();

    return '';
  }

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      return AiResponse(
        id: 'resp-no-key-${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        text: '### 🔑 Google Gemini API Key Required\n\n'
            'TrackX AI is powered live by **Google Gemini**.\n\n'
            'To start chatting, asking questions, or scanning documents, please add your free Gemini API key:\n\n'
            '1. Get your free key at **[Google AI Studio](https://aistudio.google.com/app/apikey)**.\n'
            '2. Tap **AI Settings** and paste your API key.\n\n'
            '*Gemini is completely free for personal and academic use!*',
        sources: [],
        suggestedActions: [
          AiSuggestedAction(
            type: 'OpenAiSettings',
            title: 'Open AI Settings',
            parameters: {},
          ),
        ],
        confidence: AiConfidence.limitedInformation,
        limitations: [
          'No Gemini API Key configured. Add your key in AI Settings.',
        ],
        modelId: AiConfig.geminiModel,
        createdAt: DateTime.now(),
      );
    }

    // 1. Get dynamic active model from user's key if available, or fall back to verified list
    String dynamicModel = AiConfig.geminiModel;
    try {
      dynamicModel = await AiModelManager.getActiveGeminiModel(apiKey);
    } catch (_) {}

    final candidateModels = <String>[
      if (dynamicModel != 'gemini-2.5-flash') dynamicModel,
      'gemini-3.6-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-flash-002',
      'gemini-1.5-flash-001',
      'gemini-1.5-pro',
      'gemini-pro',
    ].where((m) => m != 'gemini-2.5-flash' && !m.contains('gemini-2.5-flash')).toSet().toList();

    final systemPrompt = '''
You are Gemini, the live intelligent AI assistant in the TrackX app.
You are capable of answering ANY question asked by the user — including general knowledge, science, programming, computer science, mathematics, history, literature, essays, grammar, career advice, campus life, and study strategies, as well as specific questions regarding the student's personal timetable, attendance, courses, and exams.

Guidelines:
1. Always format responses using clean, structured Markdown (use headings, bullet points, bold highlights, tables, and formatted code blocks where appropriate).
2. Answer thoroughly, accurately, and conversationally like standard Google Gemini. Do NOT artificially limit yourself to only academic attendance topics. You can answer any topic the user is curious about!
3. If the user asks about their academic data (such as attendance, timetable, courses, upcoming exams, or study plans), refer directly to the provided student context to give precise, customized numbers and advice.
4. If the user wants to schedule a study session, take action, or check a class, mention that clearly.
5. Be encouraging, supportive, and factual.
''';

    final userPromptContent = '''
${request.context.isNotEmpty ? 'Student Academic Context:\n${jsonEncode(request.context)}\n\n' : ''}User Query:
${request.userPrompt}
''';

    String? firstError;
    String? lastError;

    for (int i = 0; i < candidateModels.length; i++) {
      final modelName = candidateModels[i];
      try {
        GenerateContentResponse response;
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            systemInstruction: Content.system(systemPrompt),
          );

          response = await model.generateContent([
            Content.text(userPromptContent),
          ]).timeout(const Duration(seconds: 25));
        } catch (callErr) {
          // If systemInstruction is unsupported or causes error, retry with instructions prepended to prompt
          final fallbackModel = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
          );
          response = await fallbackModel.generateContent([
            Content.text('Instructions:\n$systemPrompt\n\n$userPromptContent'),
          ]).timeout(const Duration(seconds: 25));
        }

        final rawText = response.text?.trim() ?? '';
        if (rawText.isEmpty) {
          continue;
        }

        // Try extracting JSON actions/sources if the model wrapped them or returned structured payload
        return _buildResponseFromText(rawText, request, modelName);
      } catch (e) {
        final errStr = e.toString();
        // If Google API error suggests a modern model (e.g. "use models/gemini-3.6-flash")
        final match = RegExp(r'models/([a-zA-Z0-9\.\-]+)').firstMatch(errStr);
        if (match != null) {
          final suggested = match.group(1);
          if (suggested != null &&
              suggested != modelName &&
              !candidateModels.contains(suggested) &&
              !suggested.contains('2.5')) {
            candidateModels.add(suggested);
          }
        }

        if (!errStr.contains('no longer available') &&
            !errStr.contains('not found') &&
            !errStr.contains('not supported')) {
          firstError ??= errStr;
        }
        lastError = errStr;
        continue;
      }
    }

    // Determine the most accurate diagnostic error message
    final rawError = (firstError != null && !firstError.contains('not found'))
        ? firstError
        : (lastError ?? 'Unknown error');
    final cleanError = rawError
        .replaceAll('Exception: ', '')
        .replaceAll('GenerativeAIException: ', '');

    return AiResponse(
      id: 'resp-err-${DateTime.now().millisecondsSinceEpoch}',
      requestId: request.id,
      text: '### ⚠️ Unable to reach Google Gemini\n\n'
          'Live connection failed: **$cleanError**\n\n'
          'Please verify:\n'
          '• Your device has an active internet connection.\n'
          '• Your Gemini API key in **AI Settings** is active and valid from [Google AI Studio](https://aistudio.google.com/app/apikey).',
      sources: [],
      suggestedActions: [
        AiSuggestedAction(
          type: 'OpenAiSettings',
          title: 'Check AI Settings',
          parameters: {},
        ),
      ],
      confidence: AiConfidence.limitedInformation,
      limitations: ['Gemini cloud service error: $cleanError'],
      modelId: AiConfig.geminiModel,
      createdAt: DateTime.now(),
    );
  }

  AiResponse _buildResponseFromText(
    String rawText,
    AiRequest request,
    String modelName,
  ) {
    String cleanedText = rawText.trim();
    if (cleanedText.startsWith('```json')) {
      cleanedText = cleanedText.substring(7);
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();
    }

    // 1. Try decoding structured JSON if returned
    if (cleanedText.startsWith('{') && cleanedText.endsWith('}')) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cleanedText);
        if (decoded.containsKey('text')) {
          final List<dynamic> rawSources = decoded['sources'] as List? ?? [];
          final sources = rawSources
              .map((e) => AiSourceReference.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          final List<dynamic> rawActions =
              decoded['suggestedActions'] as List? ?? [];
          final actions = rawActions
              .map((e) => AiSuggestedAction.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          return AiResponse(
            id: 'resp-gemini-${DateTime.now().millisecondsSinceEpoch}',
            requestId: request.id,
            text: decoded['text'] ?? rawText,
            sources: sources,
            suggestedActions: actions,
            confidence: AiConfidence.high,
            limitations: [],
            modelId: modelName,
            createdAt: DateTime.now(),
          );
        }
      } catch (_) {}
    }

    // 2. Normal natural conversational response (General Knowledge, Math, Code, Advice, Academic)
    final suggestedActions = <AiSuggestedAction>[];
    final lower = '${request.userPrompt} $rawText'.toLowerCase();

    if (lower.contains('attendance') || lower.contains('bunk') || lower.contains('target')) {
      suggestedActions.add(
        AiSuggestedAction(
          type: 'OpenAttendance',
          title: 'View Attendance',
          parameters: {},
        ),
      );
    }
    if (lower.contains('timetable') || lower.contains('period') || lower.contains('next class')) {
      suggestedActions.add(
        AiSuggestedAction(
          type: 'OpenTimetable',
          title: 'View Timetable',
          parameters: {},
        ),
      );
    }
    if (lower.contains('exam') || lower.contains('planner') || lower.contains('study plan') || lower.contains('assignment')) {
      suggestedActions.add(
        AiSuggestedAction(
          type: 'OpenPlanner',
          title: 'Open Planner',
          parameters: {},
        ),
      );
    }

    return AiResponse(
      id: 'resp-gemini-${DateTime.now().millisecondsSinceEpoch}',
      requestId: request.id,
      text: rawText,
      sources: [],
      suggestedActions: suggestedActions,
      confidence: AiConfidence.high,
      limitations: [],
      modelId: modelName,
      createdAt: DateTime.now(),
    );
  }
}
