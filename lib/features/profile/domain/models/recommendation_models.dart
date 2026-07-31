class RecommendationPreference {
  final bool enableAttendanceSuggestions;
  final bool enableStudyPlanSuggestions;
  final bool enableGroupSuggestions;
  final String updateFrequency; // 'Realtime', 'DailyDigest', 'Muted'

  RecommendationPreference({
    required this.enableAttendanceSuggestions,
    required this.enableStudyPlanSuggestions,
    required this.enableGroupSuggestions,
    required this.updateFrequency,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableAttendanceSuggestions': enableAttendanceSuggestions,
      'enableStudyPlanSuggestions': enableStudyPlanSuggestions,
      'enableGroupSuggestions': enableGroupSuggestions,
      'updateFrequency': updateFrequency,
    };
  }

  factory RecommendationPreference.fromMap(Map<String, dynamic> map) {
    return RecommendationPreference(
      enableAttendanceSuggestions: map['enableAttendanceSuggestions'] ?? true,
      enableStudyPlanSuggestions: map['enableStudyPlanSuggestions'] ?? true,
      enableGroupSuggestions: map['enableGroupSuggestions'] ?? true,
      updateFrequency: map['updateFrequency'] ?? 'Realtime',
    );
  }
}
