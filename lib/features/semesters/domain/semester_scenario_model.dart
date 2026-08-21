class SemesterScenario {
  final String id;
  final String userId;
  final String programmeId;
  final String name;
  final String? semesterId;
  final List<String> plannedSubjectIds;
  final double totalCredits;
  final double estimatedWeeklyStudyHours;
  final String status; // 'Draft', 'Preferred', 'Archived'
  final DateTime createdAt;
  final DateTime updatedAt;

  SemesterScenario({
    required this.id,
    required this.userId,
    required this.programmeId,
    required this.name,
    this.semesterId,
    required this.plannedSubjectIds,
    required this.totalCredits,
    required this.estimatedWeeklyStudyHours,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  SemesterScenario copyWith({
    String? id,
    String? userId,
    String? programmeId,
    String? name,
    String? semesterId,
    List<String>? plannedSubjectIds,
    double? totalCredits,
    double? estimatedWeeklyStudyHours,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SemesterScenario(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programmeId: programmeId ?? this.programmeId,
      name: name ?? this.name,
      semesterId: semesterId ?? this.semesterId,
      plannedSubjectIds: plannedSubjectIds ?? this.plannedSubjectIds,
      totalCredits: totalCredits ?? this.totalCredits,
      estimatedWeeklyStudyHours:
          estimatedWeeklyStudyHours ?? this.estimatedWeeklyStudyHours,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'programmeId': programmeId,
      'name': name,
      'semesterId': semesterId,
      'plannedSubjectIds': plannedSubjectIds,
      'totalCredits': totalCredits,
      'estimatedWeeklyStudyHours': estimatedWeeklyStudyHours,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SemesterScenario.fromMap(Map<String, dynamic> map) {
    return SemesterScenario(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      programmeId: map['programmeId'] ?? '',
      name: map['name'] ?? '',
      semesterId: map['semesterId'],
      plannedSubjectIds: List<String>.from(map['plannedSubjectIds'] ?? []),
      totalCredits: (map['totalCredits'] as num?)?.toDouble() ?? 0.0,
      estimatedWeeklyStudyHours:
          (map['estimatedWeeklyStudyHours'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Draft',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
