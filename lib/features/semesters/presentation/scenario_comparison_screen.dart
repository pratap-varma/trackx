import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/semesters/data/scenario_repository.dart';
import 'package:trackx/features/semesters/domain/semester_scenario_model.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/data/dependency_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/subjects/domain/subject_dependency_model.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class ScenarioComparisonScreen extends ConsumerStatefulWidget {
  const ScenarioComparisonScreen({super.key});

  @override
  ConsumerState<ScenarioComparisonScreen> createState() =>
      _ScenarioComparisonScreenState();
}

class _ScenarioComparisonScreenState
    extends ConsumerState<ScenarioComparisonScreen> {
  String? _scenarioIdA;
  String? _scenarioIdB;

  @override
  Widget build(BuildContext context) {
    final scenarios = ref
        .watch(scenarioRepositoryProvider)
        .where((s) => s.status != 'Archived')
        .toList();
    final allSubjects = ref.watch(subjectRepositoryProvider);
    final dependencies = ref.watch(dependencyRepositoryProvider);

    if (_scenarioIdA == null && scenarios.isNotEmpty) {
      _scenarioIdA = scenarios.first.id;
    }
    if (_scenarioIdB == null && scenarios.length > 1) {
      _scenarioIdB = scenarios[1].id;
    }

    final scenA = scenarios.where((s) => s.id == _scenarioIdA).firstOrNull;
    final scenB = scenarios.where((s) => s.id == _scenarioIdB).firstOrNull;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Scenario Comparison',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor),
          ),
          iconTheme: IconThemeData(color: context.textColor),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Compare custom planning scenarios side-by-side to review trade-offs.',
              style: TextStyle(color: context.subtextColor, fontSize: 11),
            ),
            const SizedBox(height: 20),

            // Scenario Selectors
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: context.isDark ? const Color(0xFF131A2B) : Colors.white,
                    initialValue: _scenarioIdA,
                    style: TextStyle(color: context.textColor, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Scenario A',
                      labelStyle: TextStyle(color: context.mutedTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: scenarios
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _scenarioIdA = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: context.isDark ? const Color(0xFF131A2B) : Colors.white,
                    initialValue: _scenarioIdB,
                    style: TextStyle(color: context.textColor, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Scenario B',
                      labelStyle: TextStyle(color: context.mutedTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: scenarios
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _scenarioIdB = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (scenA == null || scenB == null) ...[
              Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Create at least two scenarios under the Academics Hub to start comparing them.',
                    style: TextStyle(color: context.subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else ...[
              // Comparison Table
              Text(
                'Comparison Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: EdgeInsets.zero,
                child: Table(
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: context.subtleBorderColor, width: 0.5),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(1.0),
                  },
                  children: [
                    _buildHeaderRow(context, 'Metrics', scenA.name, scenB.name),
                    _buildRow(
                      context,
                      'Subjects Count',
                      '${scenA.plannedSubjectIds.length}',
                      '${scenB.plannedSubjectIds.length}',
                    ),
                    _buildRow(
                      context,
                      'Total Credits',
                      '${scenA.totalCredits}',
                      '${scenB.totalCredits}',
                    ),
                    _buildRow(
                      context,
                      'Study Hours',
                      '${scenA.estimatedWeeklyStudyHours}h',
                      '${scenB.estimatedWeeklyStudyHours}h',
                    ),
                    _buildRow(
                      context,
                      'Theory Count',
                      '${_countType(scenA, allSubjects, "Theory")}',
                      '${_countType(scenB, allSubjects, "Theory")}',
                    ),
                    _buildRow(
                      context,
                      'Laboratory Count',
                      '${_countType(scenA, allSubjects, "Laboratory")}',
                      '${_countType(scenB, allSubjects, "Laboratory")}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Trade-off evaluation
              Text(
                'Deterministic Trade-offs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _evaluateTradeOffs(
                    context,
                    scenA,
                    scenB,
                    allSubjects,
                    dependencies,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(BuildContext context, String title, String valA, String valB) {
    return TableRow(
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.subtextColor,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            valA,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.accentPurple,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            valB,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.isDark ? Colors.tealAccent : Colors.teal.shade700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildRow(BuildContext context, String label, String valA, String valB) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            label,
            style: TextStyle(color: context.mutedTextColor, fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            valA,
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            valB,
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  int _countType(SemesterScenario scen, List<Subject> all, String type) {
    return all
        .where((s) => scen.plannedSubjectIds.contains(s.id) && s.type == type)
        .length;
  }

  List<Widget> _evaluateTradeOffs(
    BuildContext context,
    SemesterScenario a,
    SemesterScenario b,
    List<Subject> all,
    List<SubjectDependency> dependencies,
  ) {
    final widgets = <Widget>[];

    // Credits comparison
    if (a.totalCredits > b.totalCredits) {
      widgets.add(
        _buildTradeOffItem(
          context,
          'Scenario A has more credits (${a.totalCredits} vs ${b.totalCredits}) but a higher learning workload.',
        ),
      );
    } else if (b.totalCredits > a.totalCredits) {
      widgets.add(
        _buildTradeOffItem(
          context,
          'Scenario B has more credits (${b.totalCredits} vs ${a.totalCredits}) but a higher learning workload.',
        ),
      );
    }

    // Study hours / Available time
    if (a.estimatedWeeklyStudyHours < b.estimatedWeeklyStudyHours) {
      widgets.add(
        _buildTradeOffItem(
          context,
          'Scenario A has fewer study hours and more available free study time.',
        ),
      );
    } else if (b.estimatedWeeklyStudyHours < a.estimatedWeeklyStudyHours) {
      widgets.add(
        _buildTradeOffItem(
          context,
          'Scenario B has fewer study hours and more available free study time.',
        ),
      );
    }

    // Unresolved prerequisite checks
    final missingA = _findMissingPrereqs(a, all, dependencies);
    final missingB = _findMissingPrereqs(b, all, dependencies);

    if (missingA.isNotEmpty) {
      widgets.add(
        _buildTradeOffItem(
          context,
          'Scenario A contains subjects (${missingA.join(", ")}) with unresolved prerequisites.',
          isWarning: true,
        ),
      );
    }
    if (missingB.isNotEmpty) {
      widgets.add(
        _buildTradeOffItem(
          context,
          'Scenario B contains subjects (${missingB.join(", ")}) with unresolved prerequisites.',
          isWarning: true,
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          'Both scenarios have balanced credits and workloads.',
          style: TextStyle(color: context.subtextColor, fontSize: 12),
        ),
      );
    }

    return widgets;
  }

  List<String> _findMissingPrereqs(
    SemesterScenario scen,
    List<Subject> all,
    List<SubjectDependency> dependencies,
  ) {
    final subjectIds = scen.plannedSubjectIds.toSet();
    final missing = <String>[];
    for (final id in subjectIds) {
      final deps = dependencies.where((d) => d.subjectId == id);
      for (final dep in deps) {
        if (!subjectIds.contains(dep.requiredSubjectId)) {
          final sub = all.where((s) => s.id == id).firstOrNull;
          if (sub != null && !missing.contains(sub.name)) {
            missing.add(sub.name);
          }
        }
      }
    }
    return missing;
  }

  Widget _buildTradeOffItem(BuildContext context, String text, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: isWarning ? Colors.amber : (context.isDark ? Colors.purpleAccent : AppTheme.accentPurple),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isWarning ? Colors.amber : context.subtextColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
