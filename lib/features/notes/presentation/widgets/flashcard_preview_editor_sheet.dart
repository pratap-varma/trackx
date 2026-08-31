import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/notes/domain/models/flashcard_model.dart';
import 'package:trackx/features/notes/providers/flashcard_provider.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:uuid/uuid.dart';

class FlashcardPreviewEditorSheet extends ConsumerStatefulWidget {
  final FlashcardDeck initialDeck;
  final ValueChanged<FlashcardDeck>? onSaved;

  const FlashcardPreviewEditorSheet({
    super.key,
    required this.initialDeck,
    this.onSaved,
  });

  static Future<FlashcardDeck?> show(
    BuildContext context, {
    required FlashcardDeck deck,
  }) {
    return showModalBottomSheet<FlashcardDeck>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => FlashcardPreviewEditorSheet(initialDeck: deck),
    );
  }

  @override
  ConsumerState<FlashcardPreviewEditorSheet> createState() =>
      _FlashcardPreviewEditorSheetState();
}

class _FlashcardPreviewEditorSheetState
    extends ConsumerState<FlashcardPreviewEditorSheet> {
  final Uuid _uuid = const Uuid();
  late TextEditingController _titleController;
  late List<Flashcard> _cards;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialDeck.title);
    _cards = List.from(widget.initialDeck.cards);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addNewCard() {
    HapticFeedback.lightImpact();
    setState(() {
      _cards.add(
        Flashcard(
          id: 'card-${_uuid.v4()}',
          deckId: widget.initialDeck.id,
          question: '',
          answer: '',
          difficulty: 'Medium',
          subjectId: widget.initialDeck.subjectId,
          sourceNoteId: widget.initialDeck.noteId,
        ),
      );
    });
  }

  void _editCard(int index) {
    final card = _cards[index];
    final qCtrl = TextEditingController(text: card.question);
    final aCtrl = TextEditingController(text: card.answer);
    final expCtrl = TextEditingController(text: card.explanation ?? '');
    String diff = card.difficulty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF0E1628),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          title: const Text(
            'Edit Flashcard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassTextField(
                  controller: qCtrl,
                  labelText: 'Question',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: aCtrl,
                  labelText: 'Answer',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: expCtrl,
                  labelText: 'Explanation / Memory Aid (Optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Difficulty:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    ...['Easy', 'Medium', 'Hard'].map((d) {
                      final isSelected = diff == d;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            d,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.white60,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF5B5FEF),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          onSelected: (_) => setDlgState(() => diff = d),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (qCtrl.text.trim().isEmpty || aCtrl.text.trim().isEmpty) return;
                setState(() {
                  _cards[index] = card.copyWith(
                    question: qCtrl.text.trim(),
                    answer: aCtrl.text.trim(),
                    explanation: expCtrl.text.trim().isEmpty ? null : expCtrl.text.trim(),
                    difficulty: diff,
                  );
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FEF),
              ),
              child: const Text('Save Card', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _commitDeck() async {
    HapticFeedback.mediumImpact();
    final validCards = _cards
        .where((c) => c.question.trim().isNotEmpty && c.answer.trim().isNotEmpty)
        .toList();

    if (validCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question and answer.')),
      );
      return;
    }

    final finalDeck = widget.initialDeck.copyWith(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : widget.initialDeck.title,
      cards: validCards,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await ref.read(flashcardsProvider.notifier).saveDeck(finalDeck);

    if (mounted) {
      Navigator.pop(context, finalDeck);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFC0C1FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Review AI Flashcards',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_cards.length} cards generated • Tap card to edit',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _addNewCard,
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: Color(0xFF7BD0FF)),
                    tooltip: 'Add Custom Card',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassTextField(
                controller: _titleController,
                labelText: 'Deck Title',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _cards.isEmpty
                  ? Center(
                      child: TextButton.icon(
                        onPressed: _addNewCard,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add your first flashcard'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(14),
                            borderColor: Colors.white.withValues(alpha: 0.08),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        card.question.isNotEmpty
                                            ? card.question
                                            : '[Blank Question - Tap to edit]',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 16, color: Color(0xFF7BD0FF)),
                                      onPressed: () => _editCard(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded,
                                          size: 16, color: Color(0xFFEF4444)),
                                      onPressed: () {
                                        setState(() {
                                          _cards.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    card.answer.isNotEmpty
                                        ? card.answer
                                        : '[Blank Answer - Tap to edit]',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _commitDeck,
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    'Save Deck (${_cards.length} Cards)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B5FEF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
