class AttendanceRecord {
  final String id;
  final String userId;
  final String semesterId;
  final String subjectId;
  final DateTime date;
  final int? periodNumber; // Supports 1 through 6
  final String status; // 'present' or 'absent'
  final String source; // 'manual', etc.
  final int createdAt;
  final int updatedAt;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.subjectId,
    required this.date,
    this.periodNumber,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? subjectId,
    DateTime? date,
    int? periodNumber,
    String? status,
    String? source,
    int? createdAt,
    int? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      periodNumber: periodNumber ?? this.periodNumber,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'date': date.toIso8601String(),
      'periodNumber': periodNumber,
      'status': status,
      'source': source,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      periodNumber: map['periodNumber'],
      status: map['status'] ?? 'present',
      source: map['source'] ?? 'manual',
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}
