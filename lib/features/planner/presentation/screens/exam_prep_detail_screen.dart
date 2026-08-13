import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class ExamPrepDetailScreen extends ConsumerStatefulWidget {
  const ExamPrepDetailScreen({super.key});

  @override
  ConsumerState<ExamPrepDetailScreen> createState() => _ExamPrepDetailScreenState();
}

class _ExamPrepDetailScreenState extends ConsumerState<ExamPrepDetailScreen> {
  final _hoursController = TextEditingController();
  final _testsController = TextEditingController();

  @override
  void dispose() {
    _hoursController.dispose();
    _testsController.dispose();
    super.dispose();
  }

  void _showEditPrepDialog(Exam exam) {
    _hoursController.text = exam.completedStudyHours.toString();
    _testsController.text = exam.practiceTestCount.toString();
    String currentConf = exam.confidence;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Update Prep Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.purple.shade900,
                    value: currentConf,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Developing', child: Text('Developing')),
                      DropdownMenuItem(value: 'Confident', child: Text('Confident')),
                      DropdownMenuItem(value: 'Strong', child: Text('Strong')),
                    ],
                    onChanged: (val) => currentConf = val ?? 'Developing',
                    decoration: InputDecoration(
                      labelText: 'Confidence Level',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hoursController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Completed Study Hours', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _testsController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Practice Test Count', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final hours = double.tryParse(_hoursController.text.trim()) ?? 0.0;
                          final tests = int.tryParse(_testsController.text.trim()) ?? 0;

                          ref.read(examsProvider.notifier).editExam(
                                exam.copyWith(
                                  confidence: currentConf,
                                  completedStudyHours: hours,
                                  practiceTestCount: tests,
                                ),
                              );
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(examsProvider);
    final subjects = ref.watch(subjectRepositoryProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Exam Preparation Planner',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: exams.isEmpty
            ? Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'No exams scheduled yet. Go to Planner to schedule exams first.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: exams.length,
                itemBuilder: (context, index) {
                  final exam = exams[index];
                  final sub = subjects.firstWhere((s) => s.id == exam.subjectId, orElse: () => Subject(id: '', userId: '', semesterId: '', name: 'Unknown Subject', facultyName: '', colorValue: 0, type: 'Theory', targetAttendance: 75, presentClasses: 0, absentClasses: 0, status: 'Active', expectedDifficulty: 'Not Set', createdAt: 0, updatedAt: 0));
                  final daysRemaining = exam.examDate.difference(DateTime.now()).inDays;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  exam.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: daysRemaining >= 0 ? Colors.blue.withValues(alpha: 0.15) : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  daysRemaining >= 0 ? '$daysRemaining Days Left' : 'Completed',
                                  style: TextStyle(
                                    color: daysRemaining >= 0 ? Colors.blueAccent : Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Subject: ${sub.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Exam Date: ${exam.examDate.year}-${exam.examDate.month}-${exam.examDate.day} at ${exam.startTime}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          const Divider(color: Colors.white10, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPrepMetric('Confidence', exam.confidence),
                              _buildPrepMetric('Hours Done', '${exam.completedStudyHours} hrs'),
                              _buildPrepMetric('Practice Tests', '${exam.practiceTestCount} tests'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showEditPrepDialog(exam),
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Update Progress', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPrepMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
