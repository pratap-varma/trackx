class SyncOperation {
  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final String operationType; // create, update, delete
  final Map<String, dynamic> payload;
  final int createdAt;
  final int retryCount;
  final int? lastAttemptAt;
  final String status; // pending, syncing, failed, completed
  final String? errorMessage;
  final String deviceId;

  SyncOperation({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    this.lastAttemptAt,
    required this.status,
    this.errorMessage,
    required this.deviceId,
  });

  SyncOperation copyWith({
    String? id,
    String? userId,
    String? entityType,
    String? entityId,
    String? operationType,
    Map<String, dynamic>? payload,
    int? createdAt,
    int? retryCount,
    int? lastAttemptAt,
    String? status,
    String? errorMessage,
    String? deviceId,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'operationType': operationType,
      'payload': payload,
      'createdAt': createdAt,
      'retryCount': retryCount,
      'lastAttemptAt': lastAttemptAt,
      'status': status,
      'errorMessage': errorMessage,
      'deviceId': deviceId,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      entityType: map['entityType'] ?? '',
      entityId: map['entityId'] ?? '',
      operationType: map['operationType'] ?? 'create',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: map['createdAt'] ?? 0,
      retryCount: map['retryCount'] ?? 0,
      lastAttemptAt: map['lastAttemptAt'],
      status: map['status'] ?? 'pending',
      errorMessage: map['errorMessage'],
      deviceId: map['deviceId'] ?? '',
    );
  }
}
