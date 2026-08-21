class Programme {
  final String id;
  final String userId;
  final String name;
  final String? degreeType;
  final String? branch;
  final int joiningYear;
  final int? expectedGraduationYear;
  final int totalSemesters;
  final double? totalCredits;
  final String gradingSystemId; // e.g. 'GPA_10', 'GPA_4', etc.
  final String? activeSemesterId;
  final String status; // 'Active', 'Completed', 'Paused', 'Archived'
  final DateTime createdAt;
  final DateTime updatedAt;

  Programme({
    required this.id,
    required this.userId,
    required this.name,
    this.degreeType,
    this.branch,
    required this.joiningYear,
    this.expectedGraduationYear,
    required this.totalSemesters,
    this.totalCredits,
    required this.gradingSystemId,
    this.activeSemesterId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Programme copyWith({
    String? id,
    String? userId,
    String? name,
    String? degreeType,
    String? branch,
    int? joiningYear,
    int? expectedGraduationYear,
    int? totalSemesters,
    double? totalCredits,
    String? gradingSystemId,
    String? activeSemesterId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Programme(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      degreeType: degreeType ?? this.degreeType,
      branch: branch ?? this.branch,
      joiningYear: joiningYear ?? this.joiningYear,
      expectedGraduationYear:
          expectedGraduationYear ?? this.expectedGraduationYear,
      totalSemesters: totalSemesters ?? this.totalSemesters,
      totalCredits: totalCredits ?? this.totalCredits,
      gradingSystemId: gradingSystemId ?? this.gradingSystemId,
      activeSemesterId: activeSemesterId ?? this.activeSemesterId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'degreeType': degreeType,
      'branch': branch,
      'joiningYear': joiningYear,
      'expectedGraduationYear': expectedGraduationYear,
      'totalSemesters': totalSemesters,
      'totalCredits': totalCredits,
      'gradingSystemId': gradingSystemId,
      'activeSemesterId': activeSemesterId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Programme.fromMap(Map<String, dynamic> map) {
    return Programme(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      degreeType: map['degreeType'],
      branch: map['branch'],
      joiningYear: map['joiningYear'] ?? DateTime.now().year,
      expectedGraduationYear: map['expectedGraduationYear'],
      totalSemesters: map['totalSemesters'] ?? 8,
      totalCredits: (map['totalCredits'] as num?)?.toDouble(),
      gradingSystemId: map['gradingSystemId'] ?? 'GPA_10',
      activeSemesterId: map['activeSemesterId'],
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
