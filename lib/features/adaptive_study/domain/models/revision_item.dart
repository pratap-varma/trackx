class RevisionItem {
  final String id;
  final String userId;
  final String subjectId;
  final String topicId;
  final int intervalStage; // 0, 1, 2, 3 spacing stages
  final DateTime dueAt;
  final DateTime lastReviewedAt;
  final String status; // 'Pending', 'Due', 'Completed', 'Skipped'

  RevisionItem({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.topicId,
    required this.intervalStage,
    required this.dueAt,
    required this.lastReviewedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subjectId': subjectId,
      'topicId': topicId,
      'intervalStage': intervalStage,
      'dueAt': dueAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt.toIso8601String(),
      'status': status,
    };
  }

  factory RevisionItem.fromMap(Map<String, dynamic> map) {
    return RevisionItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      topicId: map['topicId'] ?? '',
      intervalStage: map['intervalStage'] ?? 0,
      dueAt: DateTime.parse(map['dueAt'] ?? DateTime.now().toIso8601String()),
      lastReviewedAt: DateTime.parse(
        map['lastReviewedAt'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'Pending',
    );
  }
}
