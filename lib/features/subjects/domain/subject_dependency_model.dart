class SubjectDependency {
  final String id;
  final String userId;
  final String subjectId;
  final String requiredSubjectId;
  final String type; // 'Prerequisite', 'Corequisite', 'Recommended Background'
  final String? minimumGrade;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubjectDependency({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.requiredSubjectId,
    required this.type,
    this.minimumGrade,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  SubjectDependency copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? requiredSubjectId,
    String? type,
    String? minimumGrade,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectDependency(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      requiredSubjectId: requiredSubjectId ?? this.requiredSubjectId,
      type: type ?? this.type,
      minimumGrade: minimumGrade ?? this.minimumGrade,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subjectId': subjectId,
      'requiredSubjectId': requiredSubjectId,
      'type': type,
      'minimumGrade': minimumGrade,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SubjectDependency.fromMap(Map<String, dynamic> map) {
    return SubjectDependency(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      requiredSubjectId: map['requiredSubjectId'] ?? '',
      type: map['type'] ?? 'Prerequisite',
      minimumGrade: map['minimumGrade'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
