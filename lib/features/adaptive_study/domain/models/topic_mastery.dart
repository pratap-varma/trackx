class TopicMastery {
  final String id;
  final String userId;
  final String semesterId;
  final String subjectId;
  final String topicId;
  final String confidenceLevel; // 'NotStarted', 'Familiar', 'Confident', 'Strong'
  final int evidenceCount;
  final DateTime lastReviewedAt;
  final DateTime nextSuggestedReviewAt;

  TopicMastery({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.subjectId,
    required this.topicId,
    required this.confidenceLevel,
    required this.evidenceCount,
    required this.lastReviewedAt,
    required this.nextSuggestedReviewAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'topicId': topicId,
      'confidenceLevel': confidenceLevel,
      'evidenceCount': evidenceCount,
      'lastReviewedAt': lastReviewedAt.toIso8601String(),
      'nextSuggestedReviewAt': nextSuggestedReviewAt.toIso8601String(),
    };
  }

  factory TopicMastery.fromMap(Map<String, dynamic> map) {
    return TopicMastery(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      topicId: map['topicId'] ?? '',
      confidenceLevel: map['confidenceLevel'] ?? 'NotStarted',
      evidenceCount: map['evidenceCount'] ?? 0,
      lastReviewedAt: DateTime.parse(map['lastReviewedAt'] ?? DateTime.now().toIso8601String()),
      nextSuggestedReviewAt: DateTime.parse(map['nextSuggestedReviewAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
