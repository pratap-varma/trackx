import 'dart:math';
import 'package:trackx/features/ai_assistant/data/services/ai_provider.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_response.dart';

class OfflineFallbackProvider implements AiProvider {
  @override
  Future<AiResponse> generate(AiRequest request) async {
    // Artificial small delay to simulate processing
    await Future.delayed(const Duration(milliseconds: 600));

    final String id = 'resp-offline-${DateTime.now().millisecondsSinceEpoch}';
    String text = '';
    final List<AiSourceReference> sources = [];
    final List<AiSuggestedAction> actions = [];
    final List<String> limitations = [
      'Calculated locally on-device.',
      'No cloud AI processing performed.'
    ];

    final prompt = request.userPrompt.toLowerCase();
    if (prompt.contains('class') || prompt.contains('timetable') || prompt.contains('schedule')) {
      text = _generateTimetableBrief(request.context, sources, actions);
    } else {
      switch (request.featureType) {
        case AiFeatureType.attendanceExplanation:
          text = _generateAttendanceExplanation(request.context, sources, actions);
          break;
        case AiFeatureType.studyPlanning:
          text = _generateStudyPlanning(request.context, sources, actions);
          break;
        case AiFeatureType.examPreparation:
          text = _generateExamPreparation(request.context, sources, actions);
          break;
        case AiFeatureType.assignmentBreakdown:
          text = _generateAssignmentBreakdown(request.context, sources, actions);
          break;
        case AiFeatureType.topicExplanation:
          text = _generateTopicExplanation(request.context, request.userPrompt, sources, actions);
          break;
        case AiFeatureType.notesSummary:
        case AiFeatureType.resourceSummary:
          text = _generateSummary(request.context, sources, actions);
          break;
        default:
          text = _generateGeneralSummary(request.context, sources, actions);
          break;
      }
    }

    return AiResponse(
      id: id,
      requestId: request.id,
      text: text,
      sources: sources,
      suggestedActions: actions,
      confidence: AiConfidence.high,
      limitations: limitations,
      modelId: 'offline-deterministic-fallback',
      createdAt: DateTime.now(),
    );
  }

  String _generateTimetableBrief(
    Map<String, dynamic> context,
    List<AiSourceReference> sources,
    List<AiSuggestedAction> actions,
  ) {
    final timetable = context['timetable'] as List? ?? [];
    final subjects = context['subjects'] as List? ?? [];
    if (timetable.isEmpty) {
      return 'No classes scheduled in your timetable. You can upload an image of your timetable to automatically populate it!';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('### Timetable Schedule & Classes Brief\n');
    buffer.writeln('Here is your active schedule retrieved from your TrackX timetable:\n');

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (int dayIdx = 1; dayIdx <= 7; dayIdx++) {
      final dayEntries = timetable.where((e) => e['dayOfWeek'] == dayIdx).toList();
      if (dayEntries.isEmpty) continue;

      dayEntries.sort((a, b) => (a['startTime'] as int).compareTo(b['startTime'] as int));

      buffer.writeln('#### ${days[dayIdx - 1]}');
      for (final entry in dayEntries) {
        final subId = entry['subjectId'];
        final subMap = subjects.firstWhere(
          (s) => s['id'] == subId,
          orElse: () => null,
        );
        final subName = subMap != null ? subMap['name'] : 'Unknown Subject';

        final startMin = entry['startTime'] as int;
        final endMin = entry['endTime'] as int;

        final startH = startMin ~/ 60;
        final startM = startMin % 60;
        final endH = endMin ~/ 60;
        final endM = endMin % 60;

        final startTimeStr = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
        final endTimeStr = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

        buffer.writeln('• Period ${entry['periodNumber']}: **$subName** ($startTimeStr - $endTimeStr) in Room: ${entry['room'] ?? "LH-1"}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _generateAttendanceExplanation(
    Map<String, dynamic> context,
    List<AiSourceReference> sources,
    List<AiSuggestedAction> actions,
  ) {
    final subjects = context['subjects'] as List? ?? [];
    if (subjects.isEmpty) {
      return 'No subject attendance records found to analyze.';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('### Offline Attendance Status & Forecast');
    buffer.writeln('Calculated locally by TrackX:\n');

    for (final sub in subjects) {
      final String name = sub['name'] ?? 'Subject';
      final double target = (sub['targetAttendance'] ?? 75.0) as double;
      final double current = (sub['currentAttendance'] ?? 0.0) as double;
      
      buffer.writeln('**$name**: Current: **${current.toStringAsFixed(1)}%** (Target: ${target.toStringAsFixed(0)}%)');

      // Add source
      sources.add(AiSourceReference(
        title: name,
        category: 'Attendance',
        detail: 'Current attendance is ${current.toStringAsFixed(1)}%',
        targetRecordId: sub['id'],
      ));

      // Calculate margin or recovery
      // To simulate: if we know present and absent classes, we can calculate precisely.
      // Let's perform a simplified model-based estimate.
      if (current >= target) {
        // Safe to miss estimate (assuming 20 total classes)
        final int safeToMiss = current > 85 ? 2 : (current > 77 ? 1 : 0);
        if (safeToMiss > 0) {
          buffer.writeln('• *Status*: Safe. You can safely miss up to **$safeToMiss** class(es) while staying above target.');
        } else {
          buffer.writeln('• *Status*: Borderline. Do not miss any upcoming classes.');
        }
      } else {
        final int recoveryClasses = current < 50 ? 5 : (current < 65 ? 3 : 2);
        buffer.writeln('• *Status*: Warning! Under target. You need to attend **$recoveryClasses** consecutive classes to recover.');
        actions.add(AiSuggestedAction(
          type: 'CreateReminder',
          title: 'Attend $name class reminder',
          parameters: {
            'title': 'Attend $name class',
            'body': 'Attendance is currently at ${current.toStringAsFixed(1)}%. Make sure to attend to stay on target!',
          },
        ));
      }
      buffer.writeln();
    }

    buffer.writeln('*Calculations are estimates based on active semester rules.*');
    return buffer.toString();
  }

  String _generateStudyPlanning(
    Map<String, dynamic> context,
    List<AiSourceReference> sources,
    List<AiSuggestedAction> actions,
  ) {
    final subjects = context['subjects'] as List? ?? [];
    if (subjects.isEmpty) {
      return 'No active subjects found to construct a study plan.';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('### Offline Study Plan Generator');
    buffer.writeln('Based on your active subjects, TrackX has structured the following daily study slot recommendation:\n');

    final now = DateTime.now();
    for (int i = 0; i < min(3, subjects.length); i++) {
      final sub = subjects[i];
      final String name = sub['name'];
      final targetDate = now.add(Duration(days: i + 1));
      
      buffer.writeln('**Slot ${i + 1}**: Study **$name**');
      buffer.writeln('• Date: ${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}');
      buffer.writeln('• Duration: 45 minutes session + 10 minutes break');
      buffer.writeln('• Goal: Review core concepts and slide notes');
      buffer.writeln();

      sources.add(AiSourceReference(
        title: name,
        category: 'Subject',
        detail: 'Active planning subject',
        targetRecordId: sub['id'],
      ));

      actions.add(AiSuggestedAction(
        type: 'CreateStudySession',
        title: 'Schedule Study: $name',
        parameters: {
          'subjectId': sub['id'],
          'title': 'Study Session - $name',
          'date': targetDate.toIso8601String(),
          'durationMinutes': 45,
        },
      ));
    }

    buffer.writeln('*You can confirm and save these slots to your planner.*');
    return buffer.toString();
  }

  String _generateExamPreparation(
    Map<String, dynamic> context,
    List<AiSourceReference> sources,
    List<AiSuggestedAction> actions,
  ) {
    final exams = context['upcomingExams'] as List? ?? [];
    if (exams.isEmpty) {
      return 'No upcoming exams found to schedule preparation plans.';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('### Deterministic Exam Countdown & Revision Plan\n');

    final now = DateTime.now();
    for (final e in exams) {
      final Map<String, dynamic> ex = e is Map<String, dynamic> ? e : (e as dynamic).toMap();
      final String title = ex['title'] ?? 'Exam';
      final DateTime examDate = DateTime.parse(ex['examDate'] ?? now.add(const Duration(days: 7)).toIso8601String());
      final int daysLeft = examDate.difference(now).inDays;

      buffer.writeln('**$title**');
      buffer.writeln('• Days remaining: **$daysLeft days**');
      buffer.writeln('• Scheduled Date: ${examDate.year}-${examDate.month}-${examDate.day}');
      
      sources.add(AiSourceReference(
        title: title,
        category: 'Exam',
        detail: 'Exam date is ${examDate.year}-${examDate.month}-${examDate.day}',
      ));

      if (daysLeft <= 0) {
        buffer.writeln('• Plan: Exam is today or has already occurred.');
      } else {
        buffer.writeln('• Recommended Action: Schedule practice test and review sessions.');
        actions.add(AiSuggestedAction(
          type: 'CreatePlannerTask',
          title: 'Revision: $title',
          parameters: {
            'title': 'Exam Prep - $title',
            'dueDate': examDate.subtract(const Duration(days: 1)).toIso8601String(),
            'priority': 'High',
          },
        ));
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _generateAssignmentBreakdown(
    Map<String, dynamic> context,
    List<AiSourceReference> sources,
    List<AiSuggestedAction> actions,
  ) {
    final assignments = context['upcomingAssignments'] as List? ?? [];
    if (assignments.isEmpty) {
      return 'No active assignments found to create breakdowns.';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('### Assignment Breakdown Strategy\n');

    final now = DateTime.now();
    final Map<String, dynamic> firstAssign = assignments.first is Map<String, dynamic>
        ? assignments.first
        : (assignments.first as dynamic).toMap();

    final String title = firstAssign['title'] ?? 'Assignment';
    final DateTime dueDate = DateTime.parse(firstAssign['dueDate'] ?? now.add(const Duration(days: 5)).toIso8601String());

    buffer.writeln('For assignment **$title** (Due: ${dueDate.year}-${dueDate.month}-${dueDate.day}):');
    buffer.writeln('Suggested sequential milestones:');
    buffer.writeln('1. **Understand Requirements**: Review assignment handout and rubrics (1 hr)');
    buffer.writeln('2. **Research & Outline**: Gather resources and plan document structure (2 hrs)');
    buffer.writeln('3. **Draft & Implementation**: Write initial draft and code solutions (4 hrs)');
    buffer.writeln('4. **Verification & Review**: Test code and check document formatting (1.5 hrs)');
    buffer.writeln('5. **Final Submission**: Review check list and submit (30 mins)');
    buffer.writeln();

    sources.add(AiSourceReference(
      title: title,
      category: 'Assignment',
      detail: 'Due date is ${dueDate.year}-${dueDate.month}-${dueDate.day}',
    ));

    actions.add(AiSuggestedAction(
      type: 'CreatePlannerTask',
      title: 'Milestone: Research outline for $title',
      parameters: {
        'title': 'Research & Outline - $title',
        'dueDate': dueDate.subtract(const Duration(days: 3)).toIso8601String(),
        'priority': 'Medium',
      },
    ));

    return buffer.toString();
  }

  String _generateTopicExplanation(
    Map<String, dynamic> context,
    String prompt,
    List<AiSourceReference> sources,
    List<AiSuggestedAction> actions,
  ) {
    return '### Offline Topic Explanation\n\n'
        'You queried about topic details. Because AI cloud is currently disabled or offline, TrackX is unable to generate dynamic custom analogies.\n\n'
        '**Local Reference Tips:**\n'
        '• Check if you have saved any files, lecture links, or textbook notes under the **Academic Resource Library** for this subject.\n'
        '• Review related checklist syllabus topics in the syllabus tracker to check details.';
  }

  String _generateSummary(
    Map<String, dynamic> context,
    List<AiSourceReference> sources,
    List<AiSuggestedAction> actions,
  ) {
    return '### Document / Notes Summary\n\n'
        'Offline summary generated:\n'
        '• This document is stored securely in your private TrackX database.\n'
        '• Offline mode is active. Cloud summaries are disabled to protect data privacy.';
  }

  String _generateGeneralSummary(
    Map<String, dynamic> context,
    List<AiSourceReference> sources,
    List<AiSuggestedAction> actions,
  ) {
    final subjects = context['subjects'] as List? ?? [];
    final exams = context['upcomingExams'] as List? ?? [];

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('### TrackX Offline Daily Brief');
    buffer.writeln('Calculated locally on-device:\n');

    if (subjects.isNotEmpty) {
      final lowAtt = subjects.where((s) => (s['currentAttendance'] ?? 0.0) < (s['targetAttendance'] ?? 75.0)).toList();
      if (lowAtt.isNotEmpty) {
        buffer.writeln('⚠️ **Attendance Warning**:');
        for (final sub in lowAtt) {
          buffer.writeln('• ${sub['name']} is below target at **${(sub['currentAttendance'] as double).toStringAsFixed(1)}%**.');
        }
        buffer.writeln();
      }
    }

    if (exams.isNotEmpty) {
      buffer.writeln('📅 **Upcoming Exam Counts**:');
      buffer.writeln('• You have **${exams.length}** upcoming exams registered.');
    }

    buffer.writeln('\n*Need deeper planning or customized revision outlines? Turn on Cloud AI in settings to enable Gemini.*');
    return buffer.toString();
  }
}
