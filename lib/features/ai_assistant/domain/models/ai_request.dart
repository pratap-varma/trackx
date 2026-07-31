enum AiFeatureType {
  generalChat,
  attendanceExplanation,
  studyPlanning,
  assignmentBreakdown,
  examPreparation,
  topicExplanation,
  notesSummary,
  resourceSummary,
  revisionAdvice,
  timetableAdvice,
  creditExplanation,
  semesterScenarioExplanation
}

class AiRequest {
  final String id;
  final String userId;
  final AiFeatureType featureType;
  final String userPrompt;
  final Map<String, dynamic> context;
  final String? conversationId;
  final String modelId;
  final DateTime createdAt;

  AiRequest({
    required this.id,
    required this.userId,
    required this.featureType,
    required this.userPrompt,
    required this.context,
    this.conversationId,
    required this.modelId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'featureType': featureType.name,
      'userPrompt': userPrompt,
      'context': context,
      'conversationId': conversationId,
      'modelId': modelId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
