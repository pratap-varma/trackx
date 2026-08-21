import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_provider.dart';
import 'package:trackx/features/ai_assistant/data/services/offline_fallback_provider.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_response.dart';

class GeminiAiProvider implements AiProvider {
  final String? overrideApiKey;

  GeminiAiProvider({this.overrideApiKey});

  String _getApiKey() {
    if (overrideApiKey != null && overrideApiKey!.isNotEmpty) {
      return overrideApiKey!;
    }
    // Read from environment compilation variables
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;

    // Read from OS environment variables
    try {
      final osKey = Platform.environment['GEMINI_API_KEY'];
      if (osKey != null && osKey.isNotEmpty) return osKey;
    } catch (_) {}

    return '';
  }

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      // Seamlessly fallback to offline intelligence engine if no API key is set
      return OfflineFallbackProvider().generate(request);
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final systemPrompt = '''
You are the TrackX AI Academic Assistant, a private personal academic companion for students.
Rules:
1. Do not recommend unhealthy study schedules. Protect sleep/rest hours.
2. Under no circumstances should you edit or pretend to edit grades, marks, attendance, or course registrations.
3. Be supportive and factual. Never shame a student.
4. Output your response as a valid JSON object matching the schema below. Do not wrap it in markdown codeblocks.

JSON Schema to follow EXACTLY:
{
  "text": "Main markdown response text explaining the answers.",
  "sources": [
    {
      "title": "Display name of the reference (e.g. DBMS Attendance)",
      "category": "Category type (e.g. Attendance, Exam, Assignment, Planner)",
      "detail": "Short explanation of this reference",
      "targetRecordId": "Record identifier if applicable"
    }
  ],
  "suggestedActions": [
    {
      "type": "Action type (e.g. CreatePlannerTask, CreateStudySession, CreateReminder)",
      "title": "Label of the button to perform this action",
      "parameters": {
        "title": "Title of the task",
        "dueDate": "ISO8601 string of due date",
        "durationMinutes": 45
      }
    }
  ],
  "confidence": "high OR moderate OR limitedInformation",
  "limitations": [
    "Any warnings or missing data indicators"
  ]
}
''';

      final userPromptContent =
          '''
Context details:
${jsonEncode(request.context)}

User Query:
${request.userPrompt}
''';

      final response = await model.generateContent([
        Content.text(systemPrompt),
        Content.text(userPromptContent),
      ]);

      final rawText = response.text ?? '';

      // Clean JSON delimiters if Gemini wrapped them in ```json ... ```
      String cleanedText = rawText.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      try {
        final Map<String, dynamic> decoded = jsonDecode(cleanedText);

        final List<dynamic> rawSources = decoded['sources'] as List? ?? [];
        final sources = rawSources
            .map((e) => AiSourceReference.fromMap(Map<String, dynamic>.from(e)))
            .toList();

        final List<dynamic> rawActions =
            decoded['suggestedActions'] as List? ?? [];
        final actions = rawActions
            .map((e) => AiSuggestedAction.fromMap(Map<String, dynamic>.from(e)))
            .toList();

        final confidenceStr = decoded['confidence'] ?? 'moderate';
        final confidence = AiConfidence.values.firstWhere(
          (e) => e.name == confidenceStr,
          orElse: () => AiConfidence.moderate,
        );

        final List<dynamic> rawLimits = decoded['limitations'] as List? ?? [];
        final limitations = rawLimits.map((e) => e.toString()).toList();

        return AiResponse(
          id: 'resp-gemini-${DateTime.now().millisecondsSinceEpoch}',
          requestId: request.id,
          text: decoded['text'] ?? '',
          sources: sources,
          suggestedActions: actions,
          confidence: confidence,
          limitations: limitations,
          modelId: 'gemini-1.5-flash',
          createdAt: DateTime.now(),
        );
      } catch (_) {
        // Fallback if parsing fails
        return AiResponse(
          id: 'resp-gemini-fallback-${DateTime.now().millisecondsSinceEpoch}',
          requestId: request.id,
          text: rawText,
          sources: [],
          suggestedActions: [],
          confidence: AiConfidence.limitedInformation,
          limitations: ['Failed to parse structured JSON output from model.'],
          modelId: 'gemini-1.5-flash',
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      // If cloud Gemini fails or times out, seamlessly return local offline intelligence
      try {
        return await OfflineFallbackProvider().generate(request);
      } catch (_) {
        return AiResponse(
          id: 'resp-err-${DateTime.now().millisecondsSinceEpoch}',
          requestId: request.id,
          text:
              'I am currently working offline. Ask me about your subjects, attendance predictions, revision planning, or exams!',
          sources: [],
          suggestedActions: [],
          confidence: AiConfidence.limitedInformation,
          limitations: ['Offline mode'],
          modelId: 'offline',
          createdAt: DateTime.now(),
        );
      }
    }
  }
}
