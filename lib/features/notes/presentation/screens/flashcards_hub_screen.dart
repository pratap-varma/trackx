import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/notes/domain/models/flashcard_model.dart';
import 'package:trackx/features/notes/presentation/widgets/flashcard_preview_editor_sheet.dart';
import 'package:trackx/features/notes/providers/flashcard_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class FlashcardsHubScreen extends ConsumerWidget {
  const FlashcardsHubScreen({super.key});

  void _createNewDeck(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final newDeck = FlashcardDeck(
      id: 'deck-${const Uuid().v4()}',
      userId: 'user',
      title: 'New Study Deck',
      cards: [
        Flashcard(
          id: 'card-${const Uuid().v4()}',
          deckId: 'temp',
          question: '',
          answer: '',
        ),
      ],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final savedDeck = await FlashcardPreviewEditorSheet.show(
      context,
      deck: newDeck,
    );

    if (savedDeck != null && context.mounted) {
      context.push('/flashcards/${savedDeck.id}');
    }
  }

  void _confirmDeleteDeck(BuildContext context, WidgetRef ref, FlashcardDeck deck) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.isDark ? const Color(0xFF0E1628) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ctx.subtleBorderColor),
        ),
        title: Text(
          'Delete Deck?',
          style: TextStyle(color: ctx.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${deck.title}"? All progress on these ${deck.totalCards} cards will be removed.',
          style: TextStyle(color: ctx.subtextColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: ctx.mutedTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(flashcardsProvider.notifier).deleteDeck(deck.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(flashcardsProvider);
    final dueCount = ref.watch(dueFlashcardsCountProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Flashcards & Revision',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: context.textColor,
            ),
          ),
          iconTheme: IconThemeData(color: context.textColor),
          actions: [
            IconButton(
              icon: Icon(Icons.add_rounded, color: context.textColor),
              tooltip: 'New Deck',
              onPressed: () => _createNewDeck(context, ref),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Due Today Hero Banner
            GlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              borderColor: dueCount > 0
                  ? const Color(0xFF5B5FEF).withValues(alpha: 0.5)
                  : context.subtleBorderColor,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (dueCount > 0
                              ? const Color(0xFF5B5FEF)
                              : const Color(0xFF10B981))
                          .withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      dueCount > 0
                          ? Icons.alarm_rounded
                          : Icons.check_circle_rounded,
                      color: dueCount > 0
                          ? const Color(0xFFC0C1FF)
                          : const Color(0xFF10B981),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dueCount > 0
                              ? '$dueCount Cards Due Today'
                              : 'All Caught Up!',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dueCount > 0
                              ? 'Spaced repetition review is ready.'
                              : 'No flashcards scheduled for review.',
                          style: TextStyle(
                            color: context.mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dueCount > 0 && decks.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        // Find first deck with due cards
                        final targetDeck =
                            decks.firstWhere((d) => d.dueCardsCount > 0);
                        context.push('/flashcards/${targetDeck.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5FEF),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Study Decks',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${decks.length} Decks',
                  style: TextStyle(color: context.mutedTextColor, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (decks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.style_outlined,
                        size: 56,
                        color: context.mutedTextColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Flashcard Decks Yet',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Generate flashcards from your Lecture Notes or create a custom deck.',
                        style: TextStyle(color: context.subtextColor, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...decks.map((deck) {
                final mastery = deck.masteryPercentage.toInt();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => context.push('/flashcards/${deck.id}'),
                    borderRadius: BorderRadius.circular(18),
                    child: GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      borderColor: context.subtleBorderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (deck.subjectName != null &&
                                        deck.subjectName!.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          deck.subjectName!.toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFF7BD0FF),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      deck.title,
                                      style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (deck.dueCardsCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    '${deck.dueCardsCount} Due',
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                    size: 18, color: context.mutedTextColor),
                                onPressed: () =>
                                    _confirmDeleteDeck(context, ref, deck),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${deck.totalCards} cards • $mastery% mastered',
                                style: TextStyle(
                                  color: context.mutedTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${deck.masteredCardsCount}/${deck.totalCards}',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: deck.totalCards == 0
                                  ? 0
                                  : deck.masteredCardsCount / deck.totalCards,
                              minHeight: 5,
                              backgroundColor: context.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
