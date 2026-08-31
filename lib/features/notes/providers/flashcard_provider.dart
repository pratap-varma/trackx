import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/core/services/hive_db_service.dart';
import 'package:trackx/core/services/sync_service.dart';
import 'package:trackx/features/notes/data/services/flashcard_ai_service.dart';
import 'package:trackx/features/notes/domain/models/flashcard_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';

class FlashcardNotifier extends StateNotifier<List<FlashcardDeck>> {
  final HiveDbService _db;
  final SyncService _syncService;
  final FlashcardAiService _aiService = FlashcardAiService();

  FlashcardNotifier(this._db, this._syncService) : super([]) {
    _loadDecks();
  }

  void _loadDecks() {
    try {
      final box = _db.getBox(HiveDbService.boxFlashcards);
      final decks = box.values
          .map((e) => FlashcardDeck.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      decks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = decks;
    } catch (_) {
      state = [];
    }
  }

  Future<FlashcardDeck> generateFromNote({
    required Note note,
    String? apiKey,
    String? subjectName,
  }) async {
    final deck = await _aiService.generateDeckFromNote(
      note: note,
      apiKey: apiKey,
      subjectName: subjectName,
    );

    // Return the generated deck object so the caller can review/edit it before saving
    return deck;
  }

  Future<void> saveDeck(FlashcardDeck deck) async {
    final box = _db.getBox(HiveDbService.boxFlashcards);
    await box.put(deck.id, deck.toMap());

    // Update state
    final index = state.indexWhere((d) => d.id == deck.id);
    if (index >= 0) {
      final updatedList = List<FlashcardDeck>.from(state);
      updatedList[index] = deck;
      state = updatedList;
    } else {
      state = [deck, ...state];
    }

    // Enqueue sync operation
    await _syncService.addToQueue(
      'flashcardDeck',
      deck.id,
      'create',
      deck.toMap(),
    );
  }

  Future<void> deleteDeck(String deckId) async {
    final box = _db.getBox(HiveDbService.boxFlashcards);
    await box.delete(deckId);

    state = state.where((d) => d.id != deckId).toList();

    await _syncService.addToQueue(
      'flashcardDeck',
      deckId,
      'delete',
      {'id': deckId},
    );
  }

  Future<void> rateCardRecall({
    required String deckId,
    required String cardId,
    required int rating, // 1 = Again, 2 = Hard, 3 = Good, 4 = Easy
  }) async {
    final deckIndex = state.indexWhere((d) => d.id == deckId);
    if (deckIndex < 0) return;

    final deck = state[deckIndex];
    final cardIndex = deck.cards.indexWhere((c) => c.id == cardId);
    if (cardIndex < 0) return;

    final card = deck.cards[cardIndex];
    final updatedCard = card.applyRecallRating(rating);

    final updatedCards = List<Flashcard>.from(deck.cards);
    updatedCards[cardIndex] = updatedCard;

    final updatedDeck = deck.copyWith(
      cards: updatedCards,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await saveDeck(updatedDeck);
  }

  Future<void> resetDeckMastery(String deckId) async {
    final deckIndex = state.indexWhere((d) => d.id == deckId);
    if (deckIndex < 0) return;

    final deck = state[deckIndex];
    final updatedCards = deck.cards
        .map((c) => c.copyWith(
              isMastered: false,
              correctStreak: 0,
              intervalDays: 0,
              nextReviewDate: null,
            ))
        .toList();

    final updatedDeck = deck.copyWith(
      cards: updatedCards,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await saveDeck(updatedDeck);
  }
}

final flashcardsProvider =
    StateNotifierProvider<FlashcardNotifier, List<FlashcardDeck>>((ref) {
  final db = ref.watch(hiveDbServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return FlashcardNotifier(db, syncService);
});

final dueFlashcardsCountProvider = Provider<int>((ref) {
  final decks = ref.watch(flashcardsProvider);
  int count = 0;
  for (final deck in decks) {
    count += deck.dueCardsCount;
  }
  return count;
});
