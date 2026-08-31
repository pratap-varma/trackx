import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/features/notes/data/services/flashcard_ai_service.dart';
import 'package:trackx/features/notes/domain/models/flashcard_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';

void main() {
  group('Flashcard Domain Models & Serialization', () {
    test('Flashcard toMap and fromMap serialization roundtrip', () {
      final card = Flashcard(
        id: 'card-123',
        deckId: 'deck-abc',
        question: 'What is ACID in database systems?',
        answer: 'Atomicity, Consistency, Isolation, Durability',
        explanation: 'Ensures database transactions are processed reliably.',
        subjectId: 'sub-dbms',
        sourceNoteId: 'note-trans',
        difficulty: 'Hard',
        easeFactor: 2.35,
        intervalDays: 6,
        correctStreak: 3,
        lastReviewed: 1700000000,
        nextReviewDate: 1700518400,
        isMastered: true,
        reviewCount: 4,
      );

      final map = card.toMap();
      final roundtrip = Flashcard.fromMap(map);

      expect(roundtrip.id, equals('card-123'));
      expect(roundtrip.deckId, equals('deck-abc'));
      expect(roundtrip.question, equals(card.question));
      expect(roundtrip.answer, equals(card.answer));
      expect(roundtrip.explanation, equals(card.explanation));
      expect(roundtrip.subjectId, equals('sub-dbms'));
      expect(roundtrip.sourceNoteId, equals('note-trans'));
      expect(roundtrip.difficulty, equals('Hard'));
      expect(roundtrip.easeFactor, closeTo(2.35, 0.01));
      expect(roundtrip.intervalDays, equals(6));
      expect(roundtrip.correctStreak, equals(3));
      expect(roundtrip.isMastered, isTrue);
      expect(roundtrip.reviewCount, equals(4));
    });

    test('FlashcardDeck mastery and due calculations', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cards = [
        Flashcard(
          id: '1',
          deckId: 'd1',
          question: 'Q1',
          answer: 'A1',
          isMastered: true,
          nextReviewDate: now + 1000000, // Not due
        ),
        Flashcard(
          id: '2',
          deckId: 'd1',
          question: 'Q2',
          answer: 'A2',
          isMastered: false,
          nextReviewDate: now - 5000, // Due
        ),
        Flashcard(
          id: '3',
          deckId: 'd1',
          question: 'Q3',
          answer: 'A3',
          isMastered: true,
          nextReviewDate: null, // Due (new card)
        ),
        Flashcard(
          id: '4',
          deckId: 'd1',
          question: 'Q4',
          answer: 'A4',
          isMastered: false,
          nextReviewDate: now + 5000000, // Not due
        ),
      ];

      final deck = FlashcardDeck(
        id: 'd1',
        userId: 'u1',
        title: 'Operating Systems Revision',
        cards: cards,
        createdAt: 100,
        updatedAt: 100,
      );

      expect(deck.totalCards, equals(4));
      expect(deck.masteredCardsCount, equals(2));
      expect(deck.masteryPercentage, equals(50.0));
      expect(deck.dueCardsCount, equals(2));
    });
  });

  group('SM-2 Spaced Repetition Scheduling Algorithm', () {
    test('Rating 1 (Again) resets streak and schedules next day review', () {
      final card = Flashcard(
        id: 'c1',
        deckId: 'd1',
        question: 'Q',
        answer: 'A',
        easeFactor: 2.5,
        intervalDays: 6,
        correctStreak: 3,
        isMastered: true,
      );

      final updated = card.applyRecallRating(1);

      expect(updated.correctStreak, equals(0));
      expect(updated.intervalDays, equals(1));
      expect(updated.easeFactor, closeTo(2.3, 0.01));
      expect(updated.isMastered, isFalse);
      expect(updated.nextReviewDate, isNotNull);
    });

    test('Rating 3 (Good) scales interval by ease factor', () {
      final card = Flashcard(
        id: 'c1',
        deckId: 'd1',
        question: 'Q',
        answer: 'A',
        easeFactor: 2.5,
        intervalDays: 3,
        correctStreak: 2,
      );

      final updated = card.applyRecallRating(3);

      expect(updated.correctStreak, equals(3));
      expect(updated.intervalDays, equals(8)); // 3 * 2.5 = 7.5 -> 8
      expect(updated.isMastered, isTrue); // Streak >= 3 marks mastered
    });

    test('Rating 4 (Easy) increases ease factor and gives bonus interval', () {
      final card = Flashcard(
        id: 'c1',
        deckId: 'd1',
        question: 'Q',
        answer: 'A',
        easeFactor: 2.5,
        intervalDays: 4,
        correctStreak: 2,
      );

      final updated = card.applyRecallRating(4);

      expect(updated.easeFactor, closeTo(2.65, 0.01));
      expect(updated.intervalDays, greaterThan(10));
      expect(updated.isMastered, isTrue);
    });
  });

  group('Flashcard Offline Heuristic Generator', () {
    final aiService = FlashcardAiService();

    test('generates flashcards from structured definitions and questions', () async {
      final note = Note(
        id: 'note-1',
        userId: 'user-1',
        semesterId: 'sem-1',
        title: 'Database Transactions',
        content: '''
# Transaction Properties
Atomicity: All operations in the transaction succeed or all fail together.
Consistency: Database state remains valid before and after execution.
Isolation: Concurrent transactions do not interfere with each other.
Durability: Committed changes survive system crashes.

What is a deadlock in concurrent scheduling?
- Two or more processes waiting indefinitely for resources held by each other.
''',
        tags: ['dbms', 'exam'],
        isFavorite: true,
        localAttachmentPaths: [],
        createdAt: 1000,
        updatedAt: 1000,
      );

      final deck = await aiService.generateDeckFromNote(
        note: note,
        apiKey: null, // Test offline heuristic fallback
        subjectName: 'DBMS',
      );

      expect(deck.cards.isNotEmpty, isTrue);
      expect(deck.cards.length, greaterThanOrEqualTo(4));

      final questions = deck.cards.map((c) => c.question).toList();
      expect(questions.any((q) => q.contains('Atomicity')), isTrue);
      expect(questions.any((q) => q.contains('deadlock')), isTrue);
    });
  });
}
