class AiUsageSummary {
  final int requestsToday;
  final int requestsThisMonth;
  final int maxDailyRequests;
  final int maxMonthlyRequests;
  final int offlineFallbacksCount;

  AiUsageSummary({
    required this.requestsToday,
    required this.requestsThisMonth,
    required this.maxDailyRequests,
    required this.maxMonthlyRequests,
    required this.offlineFallbacksCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestsToday': requestsToday,
      'requestsThisMonth': requestsThisMonth,
      'maxDailyRequests': maxDailyRequests,
      'maxMonthlyRequests': maxMonthlyRequests,
      'offlineFallbacksCount': offlineFallbacksCount,
    };
  }

  factory AiUsageSummary.fromMap(Map<String, dynamic> map) {
    return AiUsageSummary(
      requestsToday: map['requestsToday'] ?? 0,
      requestsThisMonth: map['requestsThisMonth'] ?? 0,
      maxDailyRequests: map['maxDailyRequests'] ?? 20,
      maxMonthlyRequests: map['maxMonthlyRequests'] ?? 300,
      offlineFallbacksCount: map['offlineFallbacksCount'] ?? 0,
    );
  }
}
