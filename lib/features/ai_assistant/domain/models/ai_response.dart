enum AiConfidence {
  high,
  moderate,
  limitedInformation
}

class AiSourceReference {
  final String title;
  final String category; // 'Attendance', 'Exam', 'Assignment', 'Planner', etc.
  final String detail;
  final String? targetRecordId; // e.g. DBMS subjectId or assignmentId for tapping

  AiSourceReference({
    required this.title,
    required this.category,
    required this.detail,
    this.targetRecordId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'detail': detail,
      'targetRecordId': targetRecordId,
    };
  }

  factory AiSourceReference.fromMap(Map<String, dynamic> map) {
    return AiSourceReference(
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      detail: map['detail'] ?? '',
      targetRecordId: map['targetRecordId'],
    );
  }
}

class AiResponse {
  final String id;
  final String requestId;
  final String text;
  final List<AiSourceReference> sources;
  final List<AiSuggestedAction> suggestedActions;
  final AiConfidence confidence;
  final List<String> limitations;
  final String modelId;
  final DateTime createdAt;

  AiResponse({
    required this.id,
    required this.requestId,
    required this.text,
    required this.sources,
    required this.suggestedActions,
    required this.confidence,
    required this.limitations,
    required this.modelId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'text': text,
      'sources': sources.map((e) => e.toMap()).toList(),
      'suggestedActions': suggestedActions.map((e) => e.toMap()).toList(),
      'confidence': confidence.name,
      'limitations': limitations,
      'modelId': modelId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// We will define AiSuggestedAction below, but let's separate it or declare it here.
class AiSuggestedAction {
  final String type; // CreatePlannerTask, CreateStudySession, CreateReminder, SaveNote, etc.
  final String title;
  final Map<String, dynamic> parameters;

  AiSuggestedAction({
    required this.type,
    required this.title,
    required this.parameters,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'parameters': parameters,
    };
  }

  factory AiSuggestedAction.fromMap(Map<String, dynamic> map) {
    return AiSuggestedAction(
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
    );
  }
}
