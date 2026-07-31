import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();
  final _noteTitleController = TextEditingController();
  final _noteContentController = TextEditingController();
  final _noteTagsController = TextEditingController();
  String? _selectedSubjectId;

  @override
  void dispose() {
    _searchController.dispose();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    _noteTagsController.dispose();
    super.dispose();
  }

  void _showAddNoteSheet(String activeSemId, Note? existing) {
    if (existing != null) {
      _noteTitleController.text = existing.title;
      _noteContentController.text = existing.content;
      _noteTagsController.text = existing.tags.join(', ');
      _selectedSubjectId = existing.subjectId;
    } else {
      _noteTitleController.clear();
      _noteContentController.clear();
      _noteTagsController.clear();
      _selectedSubjectId = null;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final subjects = ref
            .watch(subjectRepositoryProvider)
            .where((s) => s.semesterId == activeSemId && !s.isArchived)
            .toList();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassContainer(
            borderRadius: 32.0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'Create Note' : 'Edit Note',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _noteTitleController,
                    labelText: 'Title',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _noteContentController,
                    labelText: 'Write note content here...',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _noteTagsController,
                    labelText: 'Tags (comma separated e.g. formulas, algebra)',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    dropdownColor: AppTheme.darkBgBase,
                    decoration: const InputDecoration(
                      labelText: 'Link Subject (Optional)',
                    ),
                    items: subjects
                        .map(
                          (sub) => DropdownMenuItem(
                            value: sub.id,
                            child: Text(sub.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => _selectedSubjectId = val,
                  ),
                  const SizedBox(height: 24),
                  GlassPrimaryButton(
                    text: 'Save Note',
                    onPressed: () {
                      if (_noteTitleController.text.trim().isEmpty) return;

                      final tags = _noteTagsController.text
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();

                      final note = Note(
                        id:
                            existing?.id ??
                            'note-${DateTime.now().millisecondsSinceEpoch}',
                        userId: existing?.userId ?? 'guest',
                        semesterId: activeSemId,
                        title: _noteTitleController.text.trim(),
                        content: _noteContentController.text.trim(),
                        subjectId: _selectedSubjectId,
                        tags: tags,
                        isFavorite: existing?.isFavorite ?? false,
                        localAttachmentPaths:
                            existing?.localAttachmentPaths ?? [],
                        createdAt:
                            existing?.createdAt ??
                            DateTime.now().millisecondsSinceEpoch,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      );

                      if (existing == null) {
                        ref.read(notesProvider.notifier).addNote(note);
                      } else {
                        ref.read(notesProvider.notifier).editNote(note);
                      }

                      Navigator.pop(context);
                    },
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
    final activeSem = ref.watch(activeSemesterProvider);
    final notes = ref.watch(notesProvider);

    if (activeSem == null) {
      return AppBackground(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              'Please activate a semester in Profile settings first.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ),
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final semesterNotes = notes
        .where((n) => n.semesterId == activeSem.id)
        .toList();

    final filteredNotes = semesterNotes.where((n) {
      if (query.isEmpty) return true;
      return n.title.toLowerCase().contains(query) ||
          n.content.toLowerCase().contains(query) ||
          n.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'My Notes',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_comment, color: Colors.white),
              onPressed: () => _showAddNoteSheet(activeSem.id, null),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: GlassTextField(
                controller: _searchController,
                labelText: 'Search notes by title, content or tag...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),

            // Notes List Grid
            Expanded(
              child: filteredNotes.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching notes found.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: 120,
                      ),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () => _showAddNoteSheet(activeSem.id, note),
                            child: GlassContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              note.isFavorite
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                            ),
                                            onPressed: () {
                                              ref
                                                  .read(notesProvider.notifier)
                                                  .toggleFavorite(note.id);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              ref
                                                  .read(notesProvider.notifier)
                                                  .deleteNote(note.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note.content,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (note.tags.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: note.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '#$tag',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
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
