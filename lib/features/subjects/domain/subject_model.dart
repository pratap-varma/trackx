class Subject {
  final String id;
  final String userId;
  final String semesterId;
  final String name;
  final String? code;
  final String facultyName;
  final int colorValue;
  final String type; // 'Theory', 'Laboratory', 'Project', 'Elective', 'Internship', 'Seminar', 'Workshop', 'Custom'
  final double? credits;
  final int? weeklyPeriods;
  final double targetAttendance;
  final int presentClasses;
  final int absentClasses;
  final String? grade;
  final double? marks;
  final String status; // 'Planned', 'Active', 'Completed', 'Dropped', 'Archived'
  final String expectedDifficulty; // 'Easy', 'Moderate', 'Challenging', 'Very Challenging', 'Not Set'
  final int createdAt;
  final int updatedAt;

  // Backwards compatibility getters
  double? get targetOverride => targetAttendance;
  bool get isArchived => status == 'Archived';

  Subject({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.name,
    this.code,
    required this.facultyName,
    required this.colorValue,
    required this.type,
    this.credits,
    this.weeklyPeriods,
    required this.targetAttendance,
    required this.presentClasses,
    required this.absentClasses,
    this.grade,
    this.marks,
    required this.status,
    required this.expectedDifficulty,
    required this.createdAt,
    required this.updatedAt,
  });

  Subject copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? name,
    String? code,
    String? facultyName,
    int? colorValue,
    String? type,
    double? credits,
    int? weeklyPeriods,
    double? targetAttendance,
    int? presentClasses,
    int? absentClasses,
    String? grade,
    double? marks,
    String? status,
    String? expectedDifficulty,
    int? createdAt,
    int? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      code: code ?? this.code,
      facultyName: facultyName ?? this.facultyName,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      credits: credits ?? this.credits,
      weeklyPeriods: weeklyPeriods ?? this.weeklyPeriods,
      targetAttendance: targetAttendance ?? this.targetAttendance,
      presentClasses: presentClasses ?? this.presentClasses,
      absentClasses: absentClasses ?? this.absentClasses,
      grade: grade ?? this.grade,
      marks: marks ?? this.marks,
      status: status ?? this.status,
      expectedDifficulty: expectedDifficulty ?? this.expectedDifficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'name': name,
      'code': code,
      'facultyName': facultyName,
      'colorValue': colorValue,
      'type': type,
      'credits': credits,
      'weeklyPeriods': weeklyPeriods,
      'targetAttendance': targetAttendance,
      'targetOverride': targetAttendance,
      'presentClasses': presentClasses,
      'absentClasses': absentClasses,
      'grade': grade,
      'marks': marks,
      'status': status,
      'isArchived': status == 'Archived',
      'expectedDifficulty': expectedDifficulty,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    final double targetAttendanceVal = (map['targetAttendance'] as num?)?.toDouble() ??
        (map['targetOverride'] as num?)?.toDouble() ??
        75.0;
    final status = map['status'] ?? (map['isArchived'] == true ? 'Archived' : 'Active');

    return Subject(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      name: map['name'] ?? '',
      code: map['code'],
      facultyName: map['facultyName'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF9C27B0,
      type: map['type'] ?? 'Theory',
      credits: (map['credits'] as num?)?.toDouble(),
      weeklyPeriods: map['weeklyPeriods'],
      targetAttendance: targetAttendanceVal,
      presentClasses: map['presentClasses'] ?? 0,
      absentClasses: map['absentClasses'] ?? 0,
      grade: map['grade'],
      marks: (map['marks'] as num?)?.toDouble(),
      status: status,
      expectedDifficulty: map['expectedDifficulty'] ?? 'Not Set',
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}
