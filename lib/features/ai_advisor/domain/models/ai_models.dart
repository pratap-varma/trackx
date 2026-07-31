class AiRequest {
  final String id;
  final String userId;
  final String conversationId;
  final String
  requestType; // academic_advice, attendance_advice, study_plan, etc.
  final String userMessage;
  final Map<String, dynamic> structuredContext;
  final String providerPreference; // auto, gemini, openai, offline
  final int requestedAt;
  final String locale;
  final Map<String, bool> consentFlags;
  final String appVersion;
  final int schemaVersion;

  AiRequest({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.requestType,
    required this.userMessage,
    required this.structuredContext,
    required this.providerPreference,
    required this.requestedAt,
    required this.locale,
    required this.consentFlags,
    required this.appVersion,
    required this.schemaVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'conversationId': conversationId,
      'requestType': requestType,
      'userMessage': userMessage,
      'structuredContext': structuredContext,
      'providerPreference': providerPreference,
      'requestedAt': requestedAt,
      'locale': locale,
      'consentFlags': consentFlags,
      'appVersion': appVersion,
      'schemaVersion': schemaVersion,
    };
  }

  factory AiRequest.fromMap(Map<String, dynamic> map) {
    return AiRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      conversationId: map['conversationId'] ?? '',
      requestType: map['requestType'] ?? '',
      userMessage: map['userMessage'] ?? '',
      structuredContext: Map<String, dynamic>.from(
        map['structuredContext'] ?? {},
      ),
      providerPreference: map['providerPreference'] ?? 'auto',
      requestedAt: map['requestedAt'] ?? 0,
      locale: map['locale'] ?? 'en',
      consentFlags: Map<String, bool>.from(map['consentFlags'] ?? {}),
      appVersion: map['appVersion'] ?? '1.0.0',
      schemaVersion: map['schemaVersion'] ?? 1,
    );
  }
}

class AiResponse {
  final String id;
  final String conversationId;
  final String provider;
  final String content;
  final List<StructuredAction> structuredActions;
  final int createdAt;
  final bool isOfflineFallback;
  final String safetyStatus; // safe, flagged
  final String? errorType;

  AiResponse({
    required this.id,
    required this.conversationId,
    required this.provider,
    required this.content,
    required this.structuredActions,
    required this.createdAt,
    required this.isOfflineFallback,
    required this.safetyStatus,
    this.errorType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'provider': provider,
      'content': content,
      'structuredActions': structuredActions.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'isOfflineFallback': isOfflineFallback,
      'safetyStatus': safetyStatus,
      'errorType': errorType,
    };
  }

  factory AiResponse.fromMap(Map<String, dynamic> map) {
    return AiResponse(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      provider: map['provider'] ?? '',
      content: map['content'] ?? '',
      structuredActions: (map['structuredActions'] as List? ?? [])
          .map((e) => StructuredAction.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: map['createdAt'] ?? 0,
      isOfflineFallback: map['isOfflineFallback'] ?? false,
      safetyStatus: map['safetyStatus'] ?? 'safe',
      errorType: map['errorType'],
    );
  }
}

class StructuredAction {
  final String
  type; // OpenSubject, OpenForecast, CreateStudySessionDraft, CreateTaskDraft
  final Map<String, dynamic> parameters;

  StructuredAction({required this.type, required this.parameters});

  Map<String, dynamic> toMap() => {'type': type, 'parameters': parameters};

  factory StructuredAction.fromMap(Map<String, dynamic> map) {
    return StructuredAction(
      type: map['type'] ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
    );
  }
}

class AiConversation {
  final String id;
  final String title;
  final int lastActiveAt;

  AiConversation({
    required this.id,
    required this.title,
    required this.lastActiveAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'lastActiveAt': lastActiveAt,
  };

  factory AiConversation.fromMap(Map<String, dynamic> map) {
    return AiConversation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      lastActiveAt: map['lastActiveAt'] ?? 0,
    );
  }
}

class AiMessage {
  final String id;
  final String conversationId;
  final String sender; // user, ai
  final String content;
  final int timestamp;
  final List<StructuredAction> actions;

  AiMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.actions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender,
      'content': content,
      'timestamp': timestamp,
      'actions': actions.map((e) => e.toMap()).toList(),
    };
  }

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      sender: map['sender'] ?? 'user',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      actions: (map['actions'] as List? ?? [])
          .map((e) => StructuredAction.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
