class Flashcard {
  final String id;
  final String deckId;
  final String question;
  final String answer;
  final String? explanation;
  final String? subjectId;
  final String? sourceNoteId;
  final String difficulty; // Easy, Medium, Hard
  final double easeFactor; // SM-2 Ease factor, default 2.5
  final int intervalDays; // SM-2 interval in days
  final int correctStreak; // Consecutive successful recalls
  final int? lastReviewed; // Epoch ms
  final int? nextReviewDate; // Epoch ms
  final bool isMastered;
  final int reviewCount;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    this.explanation,
    this.subjectId,
    this.sourceNoteId,
    this.difficulty = 'Medium',
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.correctStreak = 0,
    this.lastReviewed,
    this.nextReviewDate,
    this.isMastered = false,
    this.reviewCount = 0,
  });

  bool get isDue {
    if (nextReviewDate == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= nextReviewDate!;
  }

  /// Calculates the next review date using SM-2 algorithm
  /// [rating]: 1 = Again, 2 = Hard, 3 = Good, 4 = Easy
  Flashcard applyRecallRating(int rating) {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    double newEaseFactor = easeFactor;
    int newInterval = intervalDays;
    int newStreak = correctStreak;
    bool newMastered = isMastered;

    switch (rating) {
      case 1: // Again
        newStreak = 0;
        newInterval = 1;
        newEaseFactor = (easeFactor - 0.2).clamp(1.3, 3.0);
        newMastered = false;
        break;
      case 2: // Hard
        newStreak = newStreak > 0 ? newStreak : 1;
        newInterval = (intervalDays * 1.2).clamp(1, 365).round();
        newEaseFactor = (easeFactor - 0.15).clamp(1.3, 3.0);
        break;
      case 3: // Good
        newStreak += 1;
        if (newStreak == 1) {
          newInterval = 1;
        } else if (newStreak == 2) {
          newInterval = 3;
        } else {
          newInterval = (intervalDays * newEaseFactor).clamp(1, 365).round();
        }
        if (newStreak >= 3) {
          newMastered = true;
        }
        break;
      case 4: // Easy
        newStreak += 1;
        newEaseFactor = (easeFactor + 0.15).clamp(1.3, 3.0);
        if (newStreak == 1) {
          newInterval = 4;
        } else {
          newInterval =
              (intervalDays * newEaseFactor * 1.3).clamp(1, 365).round();
        }
        newMastered = true;
        break;
      default:
        newInterval = 1;
    }

    final calculatedNextReview =
        now.add(Duration(days: newInterval)).millisecondsSinceEpoch;

    return copyWith(
      easeFactor: newEaseFactor,
      intervalDays: newInterval,
      correctStreak: newStreak,
      lastReviewed: nowMs,
      nextReviewDate: calculatedNextReview,
      isMastered: newMastered,
      reviewCount: reviewCount + 1,
    );
  }

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? question,
    String? answer,
    String? explanation,
    String? subjectId,
    String? sourceNoteId,
    String? difficulty,
    double? easeFactor,
    int? intervalDays,
    int? correctStreak,
    int? lastReviewed,
    int? nextReviewDate,
    bool? isMastered,
    int? reviewCount,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      subjectId: subjectId ?? this.subjectId,
      sourceNoteId: sourceNoteId ?? this.sourceNoteId,
      difficulty: difficulty ?? this.difficulty,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      correctStreak: correctStreak ?? this.correctStreak,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      isMastered: isMastered ?? this.isMastered,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'explanation': explanation,
      'subjectId': subjectId,
      'sourceNoteId': sourceNoteId,
      'difficulty': difficulty,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'correctStreak': correctStreak,
      'lastReviewed': lastReviewed,
      'nextReviewDate': nextReviewDate,
      'isMastered': isMastered,
      'reviewCount': reviewCount,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] ?? '',
      deckId: map['deckId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      explanation: map['explanation'],
      subjectId: map['subjectId'],
      sourceNoteId: map['sourceNoteId'] ?? map['noteId'],
      difficulty: map['difficulty'] ?? 'Medium',
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: map['intervalDays'] ?? 0,
      correctStreak: map['correctStreak'] ?? 0,
      lastReviewed: map['lastReviewed'] ?? map['lastReviewedAt'],
      nextReviewDate: map['nextReviewDate'],
      isMastered: map['isMastered'] ?? false,
      reviewCount: map['reviewCount'] ?? 0,
    );
  }
}

class FlashcardDeck {
  final String id;
  final String userId;
  final String title;
  final String? noteId;
  final String? subjectId;
  final String? subjectName;
  final List<Flashcard> cards;
  final int createdAt;
  final int updatedAt;

  FlashcardDeck({
    required this.id,
    required this.userId,
    required this.title,
    this.noteId,
    this.subjectId,
    this.subjectName,
    required this.cards,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalCards => cards.length;
  int get masteredCardsCount => cards.where((c) => c.isMastered).length;
  int get dueCardsCount => cards.where((c) => c.isDue).length;
  double get masteryPercentage =>
      totalCards == 0 ? 0.0 : (masteredCardsCount / totalCards) * 100.0;

  FlashcardDeck copyWith({
    String? id,
    String? userId,
    String? title,
    String? noteId,
    String? subjectId,
    String? subjectName,
    List<Flashcard>? cards,
    int? createdAt,
    int? updatedAt,
  }) {
    return FlashcardDeck(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      noteId: noteId ?? this.noteId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'noteId': noteId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'cards': cards.map((c) => c.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory FlashcardDeck.fromMap(Map<String, dynamic> map) {
    final rawCards = map['cards'] as List? ?? [];
    return FlashcardDeck(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      noteId: map['noteId'],
      subjectId: map['subjectId'],
      subjectName: map['subjectName'],
      cards: rawCards
          .map((c) => Flashcard.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}
