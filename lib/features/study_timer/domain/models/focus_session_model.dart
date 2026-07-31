class FocusSession {
  final String id;
  final String subjectId;
  final int plannedDuration; // minutes
  final int actualDuration; // minutes
  final String status; // 'Running', 'Paused', 'Completed'
  final DateTime startedAt;

  FocusSession({
    required this.id,
    required this.subjectId,
    required this.plannedDuration,
    required this.actualDuration,
    required this.status,
    required this.startedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'plannedDuration': plannedDuration,
      'actualDuration': actualDuration,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] ?? '',
      subjectId: map['subjectId'] ?? '',
      plannedDuration: map['plannedDuration'] ?? 25,
      actualDuration: map['actualDuration'] ?? 0,
      status: map['status'] ?? 'Completed',
      startedAt: DateTime.parse(
        map['startedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
