class MigrationStatus {
  final String userId;
  final String sourceVersion;
  final String targetVersion;
  final String state; // 'Queued', 'Running', 'Completed', 'Failed'
  final int retryCount;

  MigrationStatus({
    required this.userId,
    required this.sourceVersion,
    required this.targetVersion,
    required this.state,
    required this.retryCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sourceVersion': sourceVersion,
      'targetVersion': targetVersion,
      'state': state,
      'retryCount': retryCount,
    };
  }

  factory MigrationStatus.fromMap(Map<String, dynamic> map) {
    return MigrationStatus(
      userId: map['userId'] ?? '',
      sourceVersion: map['sourceVersion'] ?? '1.0.0',
      targetVersion: map['targetVersion'] ?? '2.0.0',
      state: map['state'] ?? 'Queued',
      retryCount: map['retryCount'] ?? 0,
    );
  }
}
