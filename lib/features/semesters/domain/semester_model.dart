class Semester {
  final String id;
  final String userId;
  final String programmeId;
  final String name;
  final int semesterNumber;
  final String academicYear;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'Upcoming', 'Active', 'Completed', 'Archived'
  final double plannedCredits;
  final double completedCredits;
  final double attendanceTarget;
  final String notes;
  final int createdAt;
  final int updatedAt;

  // Backwards compatibility getters
  int? get number => semesterNumber;
  bool get isActive => status == 'Active';

  Semester({
    required this.id,
    required this.userId,
    required this.programmeId,
    required this.name,
    required this.semesterNumber,
    required this.academicYear,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.plannedCredits,
    required this.completedCredits,
    required this.attendanceTarget,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Semester copyWith({
    String? id,
    String? userId,
    String? programmeId,
    String? name,
    int? semesterNumber,
    String? academicYear,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    double? plannedCredits,
    double? completedCredits,
    double? attendanceTarget,
    String? notes,
    int? createdAt,
    int? updatedAt,
  }) {
    return Semester(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programmeId: programmeId ?? this.programmeId,
      name: name ?? this.name,
      semesterNumber: semesterNumber ?? this.semesterNumber,
      academicYear: academicYear ?? this.academicYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      plannedCredits: plannedCredits ?? this.plannedCredits,
      completedCredits: completedCredits ?? this.completedCredits,
      attendanceTarget: attendanceTarget ?? this.attendanceTarget,
      notes: notes ?? this.notes,
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
      'number': semesterNumber,
      'semesterNumber': semesterNumber,
      'academicYear': academicYear,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': status == 'Active',
      'status': status,
      'plannedCredits': plannedCredits,
      'completedCredits': completedCredits,
      'attendanceTarget': attendanceTarget,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Semester.fromMap(Map<String, dynamic> map) {
    final status =
        map['status'] ?? (map['isActive'] == true ? 'Active' : 'Completed');
    return Semester(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      programmeId: map['programmeId'] ?? '',
      name: map['name'] ?? '',
      semesterNumber: map['semesterNumber'] ?? map['number'] ?? 1,
      academicYear: map['academicYear'] ?? '',
      startDate: DateTime.parse(
        map['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      status: status,
      plannedCredits: (map['plannedCredits'] as num?)?.toDouble() ?? 0.0,
      completedCredits: (map['completedCredits'] as num?)?.toDouble() ?? 0.0,
      attendanceTarget: (map['attendanceTarget'] as num?)?.toDouble() ?? 75.0,
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}
