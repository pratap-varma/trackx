import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/core/utils/attendance_calculator.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';

class SubjectStats {
  final Subject subject;
  final int presentCount;
  final int absentCount;
  final int totalCount;
  final double percentage;
  final int safeBunks;
  final int requiredRecovery;
  final String riskLevel;
  final double target;

  SubjectStats({
    required this.subject,
    required this.presentCount,
    required this.absentCount,
    required this.totalCount,
    required this.percentage,
    required this.safeBunks,
    required this.requiredRecovery,
    required this.riskLevel,
    required this.target,
  });
}

class SemesterStats {
  final int totalPresent;
  final int totalRecorded;
  final double overallPercentage;
  final double globalTarget;
  final String? highestRiskSubjectName;
  final List<SubjectStats> subjectsBelowTarget;
  final List<SubjectStats> allSubjectStats;

  SemesterStats({
    required this.totalPresent,
    required this.totalRecorded,
    required this.overallPercentage,
    required this.globalTarget,
    this.highestRiskSubjectName,
    required this.subjectsBelowTarget,
    required this.allSubjectStats,
  });
}

// Stats Provider
final statsProvider = Provider<SemesterStats>((ref) {
  final activeSem = ref.watch(activeSemesterProvider);
  final subjects = ref.watch(subjectRepositoryProvider);
  final records = ref.watch(attendanceRepositoryProvider);
  final authState = ref.watch(authRepositoryProvider);

  final globalTarget = authState.userProfile?.globalTarget ?? 75.0;

  if (activeSem == null) {
    return SemesterStats(
      totalPresent: 0,
      totalRecorded: 0,
      overallPercentage: 0.0,
      globalTarget: globalTarget,
      subjectsBelowTarget: [],
      allSubjectStats: [],
    );
  }

  // Filter subjects and records for current semester
  final semSubjects = subjects
      .where((s) => s.semesterId == activeSem.id && !s.isArchived)
      .toList();
  final semRecords = records
      .where((r) => r.semesterId == activeSem.id)
      .toList();

  int totalPresent = 0;
  int totalRecorded = 0;
  List<SubjectStats> allStats = [];

  for (final sub in semSubjects) {
    final subRecords = semRecords.where((r) => r.subjectId == sub.id).toList();
    final present = subRecords.where((r) => r.status == 'present').length;
    final total = subRecords.length;
    final absent = total - present;

    final target = sub.targetOverride ?? globalTarget;
    final percentage = total == 0 ? 0.0 : (present / total) * 100.0;

    final safeBunks = AttendanceCalculator.calculateSafeBunks(
      present,
      total,
      target,
    );
    final recovery = AttendanceCalculator.calculateRequiredRecovery(
      present,
      total,
      target,
    );
    final risk = AttendanceCalculator.getRiskClassification(percentage, target);

    totalPresent += present;
    totalRecorded += total;

    allStats.add(
      SubjectStats(
        subject: sub,
        presentCount: present,
        absentCount: absent,
        totalCount: total,
        percentage: percentage,
        safeBunks: safeBunks,
        requiredRecovery: recovery,
        riskLevel: risk,
        target: target,
      ),
    );
  }

  final overallPercentage = totalRecorded == 0
      ? 0.0
      : (totalPresent / totalRecorded) * 100.0;

  // Identify subjects below target
  final belowTarget = allStats
      .where((s) => s.percentage < s.target && s.totalCount > 0)
      .toList();

  // Identify highest risk subject
  String? highestRiskSub;
  if (allStats.isNotEmpty) {
    // Sort by percentage ascending
    final sorted = List<SubjectStats>.from(allStats)
      ..sort((a, b) => a.percentage.compareTo(b.percentage));
    if (sorted.first.totalCount > 0 &&
        sorted.first.percentage < sorted.first.target) {
      highestRiskSub = sorted.first.subject.name;
    }
  }

  return SemesterStats(
    totalPresent: totalPresent,
    totalRecorded: totalRecorded,
    overallPercentage: overallPercentage,
    globalTarget: globalTarget,
    highestRiskSubjectName: highestRiskSub,
    subjectsBelowTarget: belowTarget,
    allSubjectStats: allStats,
  );
});
