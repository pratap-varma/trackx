import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/data/topic_repository.dart';
import 'package:trackx/features/subjects/domain/topic_model.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class TopicTrackingScreen extends ConsumerStatefulWidget {
  const TopicTrackingScreen({super.key});

  @override
  ConsumerState<TopicTrackingScreen> createState() => _TopicTrackingScreenState();
}

class _TopicTrackingScreenState extends ConsumerState<TopicTrackingScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();

  String? _selectedSubjectId;
  String _selectedDifficulty = 'Moderate';
  String _selectedConfidence = 'Developing';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _showAddTopicDialog() {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a subject first.')));
      return;
    }
    _titleController.clear();
    _descController.clear();
    _timeController.text = '45';
    _selectedDifficulty = 'Moderate';
    _selectedConfidence = 'Developing';

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
                  const Text('Add Syllabus Topic', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  GlassTextField(controller: _titleController, labelText: 'Topic Title'),
                  const SizedBox(height: 12),
                  GlassTextField(controller: _descController, labelText: 'Description'),
                  const SizedBox(height: 12),
                  GlassTextField(controller: _timeController, labelText: 'Est. Minutes', keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.purple.shade900,
                    value: _selectedDifficulty,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                      DropdownMenuItem(value: 'Challenging', child: Text('Challenging')),
                      DropdownMenuItem(value: 'Very Challenging', child: Text('Very Challenging')),
                    ],
                    onChanged: (val) => _selectedDifficulty = val ?? 'Moderate',
                    decoration: InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.purple.shade900,
                    value: _selectedConfidence,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'Not Rated', child: Text('Not Rated')),
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Developing', child: Text('Developing')),
                      DropdownMenuItem(value: 'Confident', child: Text('Confident')),
                      DropdownMenuItem(value: 'Strong', child: Text('Strong')),
                    ],
                    onChanged: (val) => _selectedConfidence = val ?? 'Developing',
                    decoration: InputDecoration(
                      labelText: 'Confidence',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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
                          final title = _titleController.text.trim();
                          final desc = _descController.text.trim();
                          final mins = int.tryParse(_timeController.text.trim()) ?? 45;

                          if (title.isNotEmpty && _selectedSubjectId != null) {
                            ref.read(topicRepositoryProvider.notifier).createTopic(
                                  subjectId: _selectedSubjectId!,
                                  title: title,
                                  description: desc.isNotEmpty ? desc : null,
                                  difficulty: _selectedDifficulty,
                                  confidence: _selectedConfidence,
                                  estimatedMinutes: mins,
                                );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add'),
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

  void _showConfidenceDialog(Topic topic) {
    String currentConf = topic.confidence;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Confidence Level', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.purple.shade900,
                  value: currentConf,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'Not Rated', child: Text('Not Rated')),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Developing', child: Text('Developing')),
                    DropdownMenuItem(value: 'Confident', child: Text('Confident')),
                    DropdownMenuItem(value: 'Strong', child: Text('Strong')),
                  ],
                  onChanged: (val) => currentConf = val ?? 'Developing',
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(topicRepositoryProvider.notifier).updateTopic(
                              topic.copyWith(confidence: currentConf),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectRepositoryProvider).where((s) => s.status != 'Archived').toList();
    final topics = ref.watch(topicRepositoryProvider);

    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    final filteredTopics = topics.where((t) => t.subjectId == _selectedSubjectId).toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Syllabus Topic Checklists',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_task, color: Colors.white),
              onPressed: _showAddTopicDialog,
            ),
          ],
        ),
        body: subjects.isEmpty
            ? Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'Create subjects first under Semester Configuration to configure syllabus topics.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: [
                  // Subject Selector
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.purple.shade900,
                      value: _selectedSubjectId,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Select Subject',
                        labelStyle: const TextStyle(color: Colors.white60),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSubjectId = val;
                        });
                      },
                    ),
                  ),

                  // List of topics
                  Expanded(
                    child: filteredTopics.isEmpty
                        ? const Center(child: Text('No topics created yet.', style: TextStyle(color: Colors.white38)))
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            itemCount: filteredTopics.length,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final items = List<Topic>.from(filteredTopics);
                              final item = items.removeAt(oldIndex);
                              items.insert(newIndex, item);
                              ref.read(topicRepositoryProvider.notifier).reorderTopics(
                                    items.map((e) => e.id).toList(),
                                  );
                            },
                            itemBuilder: (context, index) {
                              final topic = filteredTopics[index];
                              final isCompleted = topic.status == 'Completed';

                              return Padding(
                                key: ValueKey(topic.id),
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: isCompleted ? Colors.greenAccent : Colors.white60,
                                        ),
                                        onPressed: () {
                                          if (isCompleted) {
                                            ref.read(topicRepositoryProvider.notifier).updateTopic(
                                                  topic.copyWith(status: 'Not Started'),
                                                );
                                          } else {
                                            ref.read(topicRepositoryProvider.notifier).markCompleted(topic.id);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              topic.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 13,
                                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            if (topic.description != null)
                                              Text(topic.description!, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Difficulty: ${topic.difficulty} • Confidence: ${topic.confidence}',
                                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.white70, size: 18),
                                            tooltip: 'Set Confidence',
                                            onPressed: () => _showConfidenceDialog(topic),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                            onPressed: () => ref.read(topicRepositoryProvider.notifier).deleteTopic(topic.id),
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
                ],
              ),
      ),
    );
  }
}
