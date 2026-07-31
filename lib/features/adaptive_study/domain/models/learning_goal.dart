class LearningGoal {
  final String id;
  final String userId;
  final String semesterId;
  final String? subjectId;
  final String title;
  final String description;
  final String goalType; // 'StudyTime', 'TopicCompletion'
  final double targetValue;
  final double currentValue;
  final String status; // 'Active', 'Completed', 'Cancelled'
  final DateTime targetDate;

  LearningGoal({
    required this.id,
    required this.userId,
    required this.semesterId,
    this.subjectId,
    required this.title,
    required this.description,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    required this.status,
    required this.targetDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'goalType': goalType,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'status': status,
      'targetDate': targetDate.toIso8601String(),
    };
  }

  factory LearningGoal.fromMap(Map<String, dynamic> map) {
    return LearningGoal(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      goalType: map['goalType'] ?? 'StudyTime',
      targetValue: (map['targetValue'] ?? 0.0).toDouble(),
      currentValue: (map['currentValue'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Active',
      targetDate: DateTime.parse(map['targetDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}
