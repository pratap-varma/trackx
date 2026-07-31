class Topic {
  final String id;
  final String userId;
  final String subjectId;
  final String title;
  final String? description;
  final String status; // 'Not Started', 'Learning', 'Revision Needed', 'Completed', 'Archived'
  final String difficulty; // 'Easy', 'Moderate', 'Challenging', 'Very Challenging', 'Not Set'
  final String confidence; // 'Not Rated', 'Low', 'Developing', 'Confident', 'Strong'
  final int estimatedMinutes;
  final int completedMinutes;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Topic({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.title,
    this.description,
    required this.status,
    required this.difficulty,
    required this.confidence,
    required this.estimatedMinutes,
    required this.completedMinutes,
    this.lastReviewedAt,
    this.nextReviewAt,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Topic copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    String? description,
    String? status,
    String? difficulty,
    String? confidence,
    int? estimatedMinutes,
    int? completedMinutes,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Topic(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      confidence: confidence ?? this.confidence,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'status': status,
      'difficulty': difficulty,
      'confidence': confidence,
      'estimatedMinutes': estimatedMinutes,
      'completedMinutes': completedMinutes,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'nextReviewAt': nextReviewAt?.toIso8601String(),
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      status: map['status'] ?? 'Not Started',
      difficulty: map['difficulty'] ?? 'Not Set',
      confidence: map['confidence'] ?? 'Not Rated',
      estimatedMinutes: map['estimatedMinutes'] ?? 0,
      completedMinutes: map['completedMinutes'] ?? 0,
      lastReviewedAt: map['lastReviewedAt'] != null ? DateTime.parse(map['lastReviewedAt']) : null,
      nextReviewAt: map['nextReviewAt'] != null ? DateTime.parse(map['nextReviewAt']) : null,
      sortOrder: map['sortOrder'] ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }
}
