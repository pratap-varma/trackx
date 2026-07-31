class BetaEnrollment {
  final String id;
  final String userId;
  final String cohortId;
  final String enrollmentStatus; // 'Active', 'Exited', 'Completed'
  final DateTime enrolledAt;

  BetaEnrollment({
    required this.id,
    required this.userId,
    required this.cohortId,
    required this.enrollmentStatus,
    required this.enrolledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cohortId': cohortId,
      'enrollmentStatus': enrollmentStatus,
      'enrolledAt': enrolledAt.toIso8601String(),
    };
  }

  factory BetaEnrollment.fromMap(Map<String, dynamic> map) {
    return BetaEnrollment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      cohortId: map['cohortId'] ?? '',
      enrollmentStatus: map['enrollmentStatus'] ?? 'Active',
      enrolledAt: DateTime.parse(
        map['enrolledAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
