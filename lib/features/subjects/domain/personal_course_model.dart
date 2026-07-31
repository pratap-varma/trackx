class PersonalCourse {
  final String id;
  final String userId;
  final String title;
  final String? courseCode;
  final String? description;
  final double? credits;
  final String subjectType; // e.g. 'Theory', 'Laboratory', etc.
  final List<String> prerequisiteCourseIds;
  final List<int> usuallyOfferedSemesters; // e.g. [1, 3] for Odd Semesters
  final String expectedDifficulty; // 'Easy', 'Moderate', 'Challenging', 'Very Challenging', 'Not Set'
  final String? notes;
  final String status; // 'Interested', 'Planned', 'Active', 'Completed', 'Not Available', 'Archived'
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalCourse({
    required this.id,
    required this.userId,
    required this.title,
    this.courseCode,
    this.description,
    this.credits,
    required this.subjectType,
    required this.prerequisiteCourseIds,
    required this.usuallyOfferedSemesters,
    required this.expectedDifficulty,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  PersonalCourse copyWith({
    String? id,
    String? userId,
    String? title,
    String? courseCode,
    String? description,
    double? credits,
    String? subjectType,
    List<String>? prerequisiteCourseIds,
    List<int>? usuallyOfferedSemesters,
    String? expectedDifficulty,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalCourse(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      courseCode: courseCode ?? this.courseCode,
      description: description ?? this.description,
      credits: credits ?? this.credits,
      subjectType: subjectType ?? this.subjectType,
      prerequisiteCourseIds: prerequisiteCourseIds ?? this.prerequisiteCourseIds,
      usuallyOfferedSemesters: usuallyOfferedSemesters ?? this.usuallyOfferedSemesters,
      expectedDifficulty: expectedDifficulty ?? this.expectedDifficulty,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'courseCode': courseCode,
      'description': description,
      'credits': credits,
      'subjectType': subjectType,
      'prerequisiteCourseIds': prerequisiteCourseIds,
      'usuallyOfferedSemesters': usuallyOfferedSemesters,
      'expectedDifficulty': expectedDifficulty,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PersonalCourse.fromMap(Map<String, dynamic> map) {
    return PersonalCourse(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      courseCode: map['courseCode'],
      description: map['description'],
      credits: (map['credits'] as num?)?.toDouble(),
      subjectType: map['subjectType'] ?? 'Theory',
      prerequisiteCourseIds: List<String>.from(map['prerequisiteCourseIds'] ?? []),
      usuallyOfferedSemesters: List<int>.from(map['usuallyOfferedSemesters'] ?? []),
      expectedDifficulty: map['expectedDifficulty'] ?? 'Not Set',
      notes: map['notes'],
      status: map['status'] ?? 'Interested',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }
}
