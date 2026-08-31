import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_response.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_action.dart';
import 'package:trackx/features/ai_assistant/domain/validators/ai_action_validator.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class ActionConfirmationSheet extends ConsumerStatefulWidget {
  final AiSuggestedAction action;
  final String conversationId;

  const ActionConfirmationSheet({
    super.key,
    required this.action,
    required this.conversationId,
  });

  @override
  ConsumerState<ActionConfirmationSheet> createState() =>
      _ActionConfirmationSheetState();
}

class _ActionConfirmationSheetState
    extends ConsumerState<ActionConfirmationSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _priority;
  late String _category;
  late DateTime _dueDate;

  String? _validationError;

  @override
  void initState() {
    super.initState();
    final params = widget.action.parameters;
    _titleController = TextEditingController(
      text: params['title'] ?? widget.action.title,
    );
    _descController = TextEditingController(text: params['description'] ?? '');
    _priority = params['priority'] ?? 'Medium';
    _category = params['category'] ?? 'Study';

    final dateStr = params['dueDate'] ?? params['date'];
    if (dateStr != null) {
      _dueDate =
          DateTime.tryParse(dateStr) ??
          DateTime.now().add(const Duration(days: 1));
    } else {
      _dueDate = DateTime.now().add(const Duration(days: 1));
    }

    _runValidation();
  }

  void _runValidation() {
    final candidateTask = Task(
      id: 'temp',
      userId: 'user',
      semesterId: 'active',
      title: _titleController.text,
      description: _descController.text,
      category: _category,
      priority: _priority,
      dueDate: _dueDate,
      isCompleted: false,
      recurrenceRule: 'None',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final validation = AiActionValidator.validatePlannerTask(
      candidateTask,
      exams: ref.read(examsProvider),
      assignments: ref.read(assignmentsProvider),
    );

    setState(() {
      _validationError = validation.isValid ? null : validation.reason;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: GlassContainer(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Action: ${widget.action.type}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.mutedTextColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_validationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                GlassTextField(
                  controller: _titleController,
                  labelText: 'Title',
                  onChanged: (_) => _runValidation(),
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: _descController,
                  labelText: 'Description (Optional)',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: context.isDark ? const Color(0xFF131A2B) : Colors.white,
                        initialValue: _priority,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 13,
                        ),
                        items: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                          return DropdownMenuItem(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _priority = val);
                            _runValidation();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          labelStyle: TextStyle(color: context.mutedTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: context.isDark ? const Color(0xFF131A2B) : Colors.white,
                        initialValue: _category,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 13,
                        ),
                        items:
                            [
                              'Study',
                              'Assignment',
                              'Exam',
                              'Project',
                              'Other',
                            ].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _category = val);
                            _runValidation();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: context.mutedTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _dueDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _dueDate.hour,
                          _dueDate.minute,
                        );
                      });
                      _runValidation();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.subtleBorderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target Date:',
                          style: TextStyle(color: context.subtextColor, fontSize: 12),
                        ),
                        Text(
                          '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        final uid =
                            ref.read(authRepositoryProvider).userProfile?.id ??
                            'user';
                        // Log cancelled action
                        final record = AiActionRecord(
                          id: 'act-cancel-${DateTime.now().millisecondsSinceEpoch}',
                          userId: uid,
                          conversationId: widget.conversationId,
                          type: widget.action.type,
                          summary: _titleController.text,
                          status: AiActionStatus.cancelled,
                          createdAt: DateTime.now(),
                          parameters: widget.action.parameters,
                        );
                        ref
                            .read(aiActionHistoryRepositoryProvider)
                            .addActionRecord(record);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: context.mutedTextColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _validationError != null
                          ? null
                          : () {
                              final uid =
                                  ref
                                      .read(authRepositoryProvider)
                                      .userProfile
                                      ?.id ??
                                  'user';
                              final semId =
                                  ref.read(activeSemesterProvider)?.id ??
                                  'default';

                              final task = Task(
                                id: 'task-ai-${DateTime.now().millisecondsSinceEpoch}',
                                userId: uid,
                                semesterId: semId,
                                title: _titleController.text,
                                description: _descController.text,
                                category: _category,
                                priority: _priority,
                                dueDate: _dueDate,
                                isCompleted: false,
                                recurrenceRule: 'None',
                                createdAt:
                                    DateTime.now().millisecondsSinceEpoch,
                                updatedAt:
                                    DateTime.now().millisecondsSinceEpoch,
                              );

                              // Save via StateNotifier
                              ref.read(tasksProvider.notifier).addTask(task);

                              // Log confirmed action
                              final record = AiActionRecord(
                                id: 'act-confirm-${DateTime.now().millisecondsSinceEpoch}',
                                userId: uid,
                                conversationId: widget.conversationId,
                                type: widget.action.type,
                                summary: _titleController.text,
                                status: AiActionStatus.confirmed,
                                createdAt: DateTime.now(),
                                confirmedAt: DateTime.now(),
                                parameters: widget.action.parameters,
                              );
                              ref
                                  .read(aiActionHistoryRepositoryProvider)
                                  .addActionRecord(record);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Suggested AI action saved successfully.',
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPurple,
                      ),
                      child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
