import 'dart:math' as math;

class AttendanceCalculator {
  /// Calculate how many upcoming classes the student can miss/bunk
  /// while remaining at or above the target attendance rate.
  static int calculateSafeBunks(
    int attended,
    int total,
    double targetPercentage,
  ) {
    final target = targetPercentage / 100.0;
    if (total == 0) return 0;

    final currentPct = attended / total;
    if (currentPct < target) return 0;

    // Formula: attended / (total + x) >= target
    // x <= attended / target - total
    final maxBunks = (attended / target) - total;
    return math.max(0, maxBunks.floor());
  }

  /// Calculate how many consecutive classes the student must attend
  /// to reach the target attendance rate if they are currently below it.
  static int calculateRequiredRecovery(
    int attended,
    int total,
    double targetPercentage,
  ) {
    final target = targetPercentage / 100.0;
    if (total == 0) return 0;

    final currentPct = attended / total;
    if (currentPct >= target) return 0;

    if (target >= 1.0) {
      return 0; // Avoid division by zero/negative if target is 100%
    }
    final required = (target * total - attended) / (1 - target);
    return math.max(0, required.ceil());
  }

  /// Simulate predicted attendance rate based on future attendance choices
  static double simulateForecast(
    int attended,
    int total,
    int attendCount,
    int bunkCount,
  ) {
    final newAttended = attended + attendCount;
    final newTotal = total + attendCount + bunkCount;
    if (newTotal == 0) return 0.0;
    return (newAttended / newTotal) * 100.0;
  }

  /// Calculate projected attendance percentage if current session(s) are missed/bunked.
  /// Formula: (attended / (total + sessions)) * 100
  static double calculateIfBunk(int attended, int total, [int sessions = 1]) {
    final newTotal = total + sessions;
    if (newTotal <= 0) return 0.0;
    return (attended / newTotal) * 100.0;
  }

  /// Calculate projected attendance percentage if current session(s) are attended.
  /// Formula: ((attended + sessions) / (total + sessions)) * 100
  static double calculateIfAttend(int attended, int total, [int sessions = 1]) {
    final newTotal = total + sessions;
    if (newTotal <= 0) return 100.0;
    return ((attended + sessions) / newTotal) * 100.0;
  }

  /// Get the risk classification level based on percentage and target
  static String getRiskClassification(double percentage, double target) {
    if (percentage == 0 && target > 0) return 'Below Target';
    if (percentage >= 90) return 'Excellent';
    if (percentage >= target) return 'On Track';
    if (percentage >= target - 5) return 'Near Target';
    if (percentage >= target - 15) return 'At Risk';
    return 'Below Target';
  }
}
