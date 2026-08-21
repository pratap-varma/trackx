class PracticeSession {
  final String id;
  final String userId;
  final String semesterId;
  final String subjectId;
  final String? topicId;
  final String practiceType; // 'Recall', 'Quiz', 'PastPaper'
  final int plannedDuration; // in minutes
  final int actualDuration;
  final double? score;
  final double? maximumScore;
  final int selfRating; // 1-5 scale
  final DateTime startedAt;
  final DateTime completedAt;

  PracticeSession({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.subjectId,
    this.topicId,
    required this.practiceType,
    required this.plannedDuration,
    required this.actualDuration,
    this.score,
    this.maximumScore,
    required this.selfRating,
    required this.startedAt,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'topicId': topicId,
      'practiceType': practiceType,
      'plannedDuration': plannedDuration,
      'actualDuration': actualDuration,
      'score': score,
      'maximumScore': maximumScore,
      'selfRating': selfRating,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory PracticeSession.fromMap(Map<String, dynamic> map) {
    return PracticeSession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      topicId: map['topicId'],
      practiceType: map['practiceType'] ?? 'Recall',
      plannedDuration: map['plannedDuration'] ?? 30,
      actualDuration: map['actualDuration'] ?? 0,
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
      maximumScore: map['maximumScore'] != null
          ? (map['maximumScore'] as num).toDouble()
          : null,
      selfRating: map['selfRating'] ?? 3,
      startedAt: DateTime.parse(
        map['startedAt'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: DateTime.parse(
        map['completedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
