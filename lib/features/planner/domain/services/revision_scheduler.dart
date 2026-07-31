import 'package:trackx/features/subjects/domain/topic_model.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';

class RevisionScheduleResult {
  final DateTime suggestedDate;
  final int suggestedDurationMinutes;
  final String reason;
  final List<DateTime> alternativeDates;

  RevisionScheduleResult({
    required this.suggestedDate,
    required this.suggestedDurationMinutes,
    required this.reason,
    required this.alternativeDates,
  });
}

class RevisionScheduler {
  static RevisionScheduleResult scheduleRevision({
    required Topic topic,
    required DateTime? examDate,
    required int preferredStudySessionMinutes,
    required List<DateTime> existingCommitmentDates,
    DateTime? lastReviewDate,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 1. Determine baseline interval based on confidence and difficulty
    int diffWeight = 2; // Default Moderate
    switch (topic.difficulty) {
      case 'Easy':
        diffWeight = 1;
        break;
      case 'Moderate':
        diffWeight = 2;
        break;
      case 'Challenging':
        diffWeight = 3;
        break;
      case 'Very Challenging':
        diffWeight = 4;
        break;
    }

    int confWeight = 3; // Default Developing
    switch (topic.confidence) {
      case 'Strong':
        confWeight = 1;
        break;
      case 'Confident':
        confWeight = 2;
        break;
      case 'Developing':
        confWeight = 3;
        break;
      case 'Low':
      case 'Not Rated':
        confWeight = 4;
        break;
    }

    // Intensity: higher means needs review sooner
    final intensity = diffWeight + confWeight; 
    
    // Suggested interval in days
    int intervalDays = 4;
    if (intensity >= 7) {
      intervalDays = 1; // High difficulty, low confidence -> review almost daily
    } else if (intensity >= 5) {
      intervalDays = 3;
    } else if (intensity >= 3) {
      intervalDays = 7;
    } else {
      intervalDays = 14; // Easy + Strong confidence -> review in 2 weeks
    }

    // Last review date or start from today
    final baseDate = lastReviewDate ?? today;
    DateTime suggested = baseDate.add(Duration(days: intervalDays));
    if (suggested.isBefore(today)) {
      suggested = today; // Supportive rescheduling for missed reviews
    }

    // Check against exam date. Must be scheduled before the exam.
    if (examDate != null) {
      final lastPossibleDate = examDate.subtract(const Duration(days: 1));
      if (suggested.isAfter(lastPossibleDate)) {
        suggested = lastPossibleDate.isAfter(today) ? lastPossibleDate : today;
      }
    }

    // 2. Adjust for existing commitments (avoid overcrowding a day)
    // We assume a day is overcrowded if there is an existing commitment on it.
    // If suggested date is overcrowded, try next available day.
    int maxSearchDays = 10;
    while (maxSearchDays > 0) {
      final isOvercrowded = existingCommitmentDates.any((d) =>
          d.year == suggested.year &&
          d.month == suggested.month &&
          d.day == suggested.day);
      if (isOvercrowded) {
        suggested = suggested.add(const Duration(days: 1));
        // Clamp to exam date minus 1 if exam is set
        if (examDate != null) {
          final lastPossible = examDate.subtract(const Duration(days: 1));
          if (suggested.isAfter(lastPossible)) {
            suggested = lastPossible;
            break;
          }
        }
      } else {
        break;
      }
      maxSearchDays--;
    }

    // 3. Determine duration
    int duration = preferredStudySessionMinutes;
    if (intensity >= 7) {
      duration = (preferredStudySessionMinutes * 1.5).round(); // Extend session for challenging topics
    } else if (intensity <= 3) {
      duration = (preferredStudySessionMinutes * 0.8).round(); // Shorter session for strong topics
    }

    // 4. Generate alternatives
    final alternativeDates = <DateTime>[];
    for (int i = 1; i <= 3; i++) {
      final alt = suggested.add(Duration(days: i));
      if (examDate == null || alt.isBefore(examDate)) {
        alternativeDates.add(alt);
      }
    }

    // 5. Construct reasons
    String reason = '';
    if (intensity >= 7) {
      reason = 'High difficulty and low confidence. Recommended to review sooner for active recall.';
    } else if (topic.confidence == 'Strong') {
      reason = 'Strong confidence level. A spaced-repetition refresh is suggested to maintain retention.';
    } else {
      reason = 'Based on moderate topic complexity. Clean slot scheduled before exam date.';
    }

    return RevisionScheduleResult(
      suggestedDate: suggested,
      suggestedDurationMinutes: duration,
      reason: reason,
      alternativeDates: alternativeDates,
    );
  }
}
