import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/notes/domain/models/flashcard_model.dart';
import 'package:trackx/features/notes/providers/flashcard_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class FlashcardStudyScreen extends ConsumerStatefulWidget {
  final String deckId;

  const FlashcardStudyScreen({super.key, required this.deckId});

  @override
  ConsumerState<FlashcardStudyScreen> createState() =>
      _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isSessionFinished = false;

  final Map<int, int> _sessionRatingCounts = {1: 0, 2: 0, 3: 0, 4: 0};

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flipAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutBack,
    ));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.selectionClick();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _rateRecall(int rating, FlashcardDeck deck) {
    HapticFeedback.lightImpact();
    final card = deck.cards[_currentIndex];

    _sessionRatingCounts[rating] = (_sessionRatingCounts[rating] ?? 0) + 1;

    ref.read(flashcardsProvider.notifier).rateCardRecall(
          deckId: deck.id,
          cardId: card.id,
          rating: rating,
        );

    if (_currentIndex < deck.cards.length - 1) {
      if (_isFlipped) {
        _flipController.reverse();
        _isFlipped = false;
      }
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _isSessionFinished = true;
      });
    }
  }

  void _restartSession({bool resetMastery = false}) {
    if (resetMastery) {
      ref.read(flashcardsProvider.notifier).resetDeckMastery(widget.deckId);
    }
    if (_isFlipped) {
      _flipController.reverse();
      _isFlipped = false;
    }
    setState(() {
      _currentIndex = 0;
      _isSessionFinished = false;
      _sessionRatingCounts.updateAll((key, value) => 0);
    });
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(flashcardsProvider);
    final deck = decks.firstWhere(
      (d) => d.id == widget.deckId,
      orElse: () => FlashcardDeck(
        id: '',
        userId: '',
        title: 'Flashcards',
        cards: [],
        createdAt: 0,
        updatedAt: 0,
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFDEE2F4) : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final mutedTextColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    if (deck.id.isEmpty) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text('Study Flashcards', style: TextStyle(color: textColor)),
          ),
          body: Center(
            child: Text(
              'Deck not found.',
              style: TextStyle(color: subtextColor),
            ),
          ),
        ),
      );
    }

    if (deck.cards.isEmpty) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text('Study Flashcards', style: TextStyle(color: textColor)),
          ),
          body: Center(
            child: Text(
              'No flashcards found in this deck.',
              style: TextStyle(color: subtextColor),
            ),
          ),
        ),
      );
    }

    if (_isSessionFinished) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(deck.title, style: TextStyle(color: textColor)),
          ),
          body: _buildCompletionView(deck, isDark, textColor, subtextColor),
        ),
      );
    }

    final currentCard = deck.cards[_currentIndex];
    final progress = (_currentIndex + 1) / deck.cards.length;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            deck.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textColor,
            ),
          ),
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Streak: ${currentCard.correctStreak}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Card ${_currentIndex + 1} of ${deck.cards.length}',
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(currentCard.difficulty)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getDifficultyColor(currentCard.difficulty)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            currentCard.difficulty,
                            style: TextStyle(
                              color: _getDifficultyColor(currentCard.difficulty),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF5B5FEF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 3D Flip Flashcard
              GestureDetector(
                onTap: _flipCard,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * math.pi;
                      final isUnder = _flipAnimation.value > 0.5;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0015)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isUnder
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(math.pi),
                                alignment: Alignment.center,
                                child: _buildCardBack(currentCard, isDark, textColor, subtextColor, mutedTextColor),
                              )
                            : _buildCardFront(currentCard, isDark, textColor, subtextColor, mutedTextColor),
                      );
                    },
                  ),
                ),
              ),

              const Spacer(),

              // SM-2 Recall Rating Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    if (!_isFlipped)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Tap card to reveal answer before rating',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        // 1. Again
                        Expanded(
                          child: _buildRecallButton(
                            label: 'Again',
                            intervalLabel: '< 1d',
                            color: const Color(0xFFEF4444),
                            onTap: () => _rateRecall(1, deck),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. Hard
                        Expanded(
                          child: _buildRecallButton(
                            label: 'Hard',
                            intervalLabel: '1.2x',
                            color: const Color(0xFFF59E0B),
                            onTap: () => _rateRecall(2, deck),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 3. Good
                        Expanded(
                          child: _buildRecallButton(
                            label: 'Good',
                            intervalLabel: 'SM-2',
                            color: const Color(0xFF3B82F6),
                            onTap: () => _rateRecall(3, deck),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 4. Easy
                        Expanded(
                          child: _buildRecallButton(
                            label: 'Easy',
                            intervalLabel: '+Bonus',
                            color: const Color(0xFF10B981),
                            onTap: () => _rateRecall(4, deck),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecallButton({
    required String label,
    required String intervalLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            intervalLabel,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(Flashcard card, bool isDark, Color textColor, Color subtextColor, Color mutedTextColor) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(28),
      borderColor: const Color(0xFF5B5FEF).withValues(alpha: 0.4),
      child: Container(
        constraints: const BoxConstraints(minHeight: 280),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'QUESTION',
                style: TextStyle(
                  color: Color(0xFFC0C1FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              card.question,
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: mutedTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap card to reveal answer',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(Flashcard card, bool isDark, Color textColor, Color subtextColor, Color mutedTextColor) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(28),
      borderColor: const Color(0xFF10B981).withValues(alpha: 0.5),
      child: Container(
        constraints: const BoxConstraints(minHeight: 280),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ANSWER',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              card.answer,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (card.explanation != null && card.explanation!.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '💡 ${card.explanation}',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionView(FlashcardDeck deck, bool isDark, Color textColor, Color subtextColor) {
    final percentage = deck.masteryPercentage.toInt();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: GlassContainer(
          borderRadius: 28,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Review Session Complete!',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Overall Deck Mastery: $percentage% (${deck.masteredCardsCount}/${deck.totalCards} cards)',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Session Breakdown Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBreakdownChip('Again', _sessionRatingCounts[1] ?? 0, const Color(0xFFEF4444), subtextColor),
                  _buildBreakdownChip('Hard', _sessionRatingCounts[2] ?? 0, const Color(0xFFF59E0B), subtextColor),
                  _buildBreakdownChip('Good', _sessionRatingCounts[3] ?? 0, const Color(0xFF3B82F6), subtextColor),
                  _buildBreakdownChip('Easy', _sessionRatingCounts[4] ?? 0, const Color(0xFF10B981), subtextColor),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _restartSession(resetMastery: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B5FEF),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Practice Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Done / Return to Hub',
                    style: TextStyle(
                      color: subtextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownChip(String label, int count, Color color, Color subtextColor) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: subtextColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
