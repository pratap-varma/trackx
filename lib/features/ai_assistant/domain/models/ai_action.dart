enum AiActionStatus {
  suggested,
  confirmed,
  edited,
  cancelled,
  failed,
  completed
}

class AiActionRecord {
  final String id;
  final String userId;
  final String conversationId;
  final String type; // CreatePlannerTask, CreateStudySession, CreateReminder, SaveNote
  final String summary;
  final AiActionStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final Map<String, dynamic> parameters;

  AiActionRecord({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.type,
    required this.summary,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    required this.parameters,
  });

  AiActionRecord copyWith({
    String? id,
    String? userId,
    String? conversationId,
    String? type,
    String? summary,
    AiActionStatus? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    Map<String, dynamic>? parameters,
  }) {
    return AiActionRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      parameters: parameters ?? this.parameters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'conversationId': conversationId,
      'type': type,
      'summary': summary,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'parameters': parameters,
    };
  }

  factory AiActionRecord.fromMap(Map<String, dynamic> map) {
    return AiActionRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      conversationId: map['conversationId'] ?? '',
      type: map['type'] ?? '',
      summary: map['summary'] ?? '',
      status: AiActionStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => AiActionStatus.suggested),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      confirmedAt: map['confirmedAt'] != null ? DateTime.parse(map['confirmedAt']) : null,
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
    );
  }
}
