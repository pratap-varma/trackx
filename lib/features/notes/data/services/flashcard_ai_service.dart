import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:trackx/core/services/activity_logger.dart';
import 'package:trackx/features/notes/domain/models/flashcard_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:uuid/uuid.dart';

class FlashcardAiService {
  final Uuid _uuid = const Uuid();

  Future<FlashcardDeck> generateDeckFromNote({
    required Note note,
    String? apiKey,
    String? subjectName,
  }) async {
    final deckId = 'deck-${_uuid.v4()}';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    ActivityLogger().logEvent('ai_feature_used', userId: note.userId, parameters: {
      'feature': 'flashcard_generator',
      'deck_id': deckId,
    });

    List<Flashcard> cards = [];

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        cards = await _generateWithGemini(
          note: note,
          apiKey: apiKey.trim(),
          deckId: deckId,
          subjectName: subjectName,
        );
      } catch (_) {
        cards = [];
      }
    }

    // If Gemini was offline or returned empty, use the heuristic offline engine
    if (cards.isEmpty) {
      cards = _generateWithOfflineEngine(
        note: note,
        deckId: deckId,
      );
    }

    return FlashcardDeck(
      id: deckId,
      userId: note.userId,
      title: '${note.title.isNotEmpty ? note.title : 'Study'} Flashcards',
      noteId: note.id,
      subjectId: note.subjectId,
      subjectName: subjectName,
      cards: cards,
      createdAt: nowMs,
      updatedAt: nowMs,
    );
  }

  Future<List<Flashcard>> _generateWithGemini({
    required Note note,
    required String apiKey,
    required String deckId,
    String? subjectName,
  }) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
You are an expert university academic coach and tutor.
Generate 5 to 10 high-yield flashcard questions and answers for exam revision based on the student's lecture note below.

Subject: ${subjectName ?? 'Academic Subject'}
Note Title: ${note.title}
Note Content:
${note.content}

Requirements:
1. Output ONLY a valid JSON array of objects with the exact schema below.
2. Formulate clear, concise questions and informative answers suitable for active recall and spaced repetition.
3. Classify difficulty as "Easy", "Medium", or "Hard".
4. Provide a brief 1-2 sentence explanation or memory aid for each card.

JSON Schema:
[
  {
    "question": "What is the primary function of ...?",
    "answer": "Direct concise answer.",
    "explanation": "Brief context or mnemonic.",
    "difficulty": "Medium"
  }
]
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text ?? '';
    String cleaned = raw.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final List decoded = jsonDecode(cleaned);
    return decoded.map((item) {
      final m = Map<String, dynamic>.from(item as Map);
      return Flashcard(
        id: 'card-${_uuid.v4()}',
        deckId: deckId,
        question: m['question'] ?? 'Concept Question',
        answer: m['answer'] ?? 'Answer',
        explanation: m['explanation'],
        difficulty: m['difficulty'] ?? 'Medium',
        isMastered: false,
        reviewCount: 0,
      );
    }).toList();
  }

  List<Flashcard> _generateWithOfflineEngine({
    required Note note,
    required String deckId,
  }) {
    final List<Flashcard> cards = [];
    final lines = note.content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Pattern 1: Term: Definition or Term - Definition
      if (trimmed.contains(': ') || trimmed.contains(' - ')) {
        final delimiter = trimmed.contains(': ') ? ': ' : ' - ';
        final parts = trimmed.split(delimiter);
        if (parts.length >= 2 &&
            parts[0].trim().length > 2 &&
            parts[1].trim().length > 4) {
          final term = parts[0]
              .replaceAll('*', '')
              .replaceAll('#', '')
              .replaceAll('-', '')
              .trim();
          final definition = parts.sublist(1).join(delimiter).trim();

          cards.add(
            Flashcard(
              id: 'card-${_uuid.v4()}',
              deckId: deckId,
              question: 'What is "$term"?',
              answer: definition,
              explanation: 'Key definition extracted from your notes.',
              difficulty: definition.length > 80 ? 'Hard' : 'Medium',
              isMastered: false,
            ),
          );
        }
      }
      // Pattern 2: Question with Question Mark
      else if (trimmed.endsWith('?')) {
        cards.add(
          Flashcard(
            id: 'card-${_uuid.v4()}',
            deckId: deckId,
            question: trimmed,
            answer: 'Review corresponding concept in ${note.title}.',
            explanation: 'Inquiry topic noted during class.',
            difficulty: 'Medium',
            isMastered: false,
          ),
        );
      }
      // Pattern 3: Bullet points starting with - or *
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final point = trimmed.substring(2).trim();
        if (point.length > 15) {
          cards.add(
            Flashcard(
              id: 'card-${_uuid.v4()}',
              deckId: deckId,
              question: 'Explain the concept regarding: ${point.split(' ').take(4).join(' ')}...',
              answer: point,
              explanation: 'Important summary point.',
              difficulty: 'Easy',
              isMastered: false,
            ),
          );
        }
      }
    }

    // Fallback if note was too short or lacked delimiters: create summary card
    if (cards.isEmpty) {
      cards.add(
        Flashcard(
          id: 'card-${_uuid.v4()}',
          deckId: deckId,
          question: 'What are the main concepts covered in "${note.title}"?',
          answer: note.content.isNotEmpty
              ? (note.content.length > 250
                  ? '${note.content.substring(0, 250)}...'
                  : note.content)
              : 'Review lecture notes for details.',
          explanation: 'Core overview summary card.',
          difficulty: 'Easy',
          isMastered: false,
        ),
      );
    }

    return cards;
  }
}
