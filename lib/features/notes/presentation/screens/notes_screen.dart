import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';

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
  List<String> _attachedFilePaths = [];

  @override
  void dispose() {
    _searchController.dispose();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    _noteTagsController.dispose();
    super.dispose();
  }

  void _previewAttachment(String path) {
    final isPdf = path.toLowerCase().endsWith('.pdf');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      path,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Center(
                  child: isPdf
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Color(0xFFEF4444),
                              size: 56,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '[PDF Preview]',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.photo_rounded,
                              color: Color(0xFF7BD0FF),
                              size: 56,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '[Image Preview]',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions(StateSetter setSheetState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Attach Document or Photo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              (
                'Upload Document (PDF)',
                Icons.picture_as_pdf_rounded,
                const Color(0xFFEF4444),
              ),
              (
                'Upload Image (.PNG / .JPG)',
                Icons.photo_rounded,
                const Color(0xFF7BD0FF),
              ),
              (
                'Resource Reference Note',
                Icons.description_rounded,
                const Color(0xFF10B981),
              ),
            ].map(
              (item) => GestureDetector(
                onTap: () {
                  setSheetState(
                    () => _attachedFilePaths.add(
                      '${item.$1}_${DateTime.now().millisecondsSinceEpoch}',
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$2, color: item.$3, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteSheet(String activeSemId, Note? existing) {
    if (existing != null) {
      _noteTitleController.text = existing.title;
      _noteContentController.text = existing.content;
      _noteTagsController.text = existing.tags.join(', ');
      _selectedSubjectId = existing.subjectId;
      _attachedFilePaths = List.from(existing.localAttachmentPaths);
    } else {
      _noteTitleController.clear();
      _noteContentController.clear();
      _noteTagsController.clear();
      _selectedSubjectId = null;
      _attachedFilePaths = [];
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

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0E1628),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        existing == null ? 'New Note' : 'Edit Note',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GlassTextField(
                        controller: _noteTitleController,
                        labelText: 'Title',
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _noteContentController,
                        labelText: 'Write note content...',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _noteTagsController,
                        labelText: 'Tags (comma separated)',
                      ),
                      const SizedBox(height: 16),

                      // Subject link dropdown
                      if (subjects.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedSubjectId,
                              hint: const Text(
                                'Link to Subject (optional)',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                              dropdownColor: const Color(0xFF1B1F2C),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              icon: Icon(
                                Icons.expand_more_rounded,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'None',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ),
                                ...subjects.map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setSheetState(() => _selectedSubjectId = val),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Attachments
                      if (_attachedFilePaths.isNotEmpty) ...[
                        const Text(
                          'Attachments',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _attachedFilePaths.map((path) {
                            final isPdf = path.toLowerCase().endsWith('.pdf');
                            return Chip(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.05,
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              avatar: Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.photo,
                                size: 14,
                                color: isPdf
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF7BD0FF),
                              ),
                              label: Text(
                                path,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.cancel,
                                size: 14,
                                color: Colors.white38,
                              ),
                              onDeleted: () => setSheetState(
                                () => _attachedFilePaths.remove(path),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showAttachmentOptions(setSheetState),
                              icon: const Icon(
                                Icons.attach_file_rounded,
                                size: 16,
                              ),
                              label: const Text('Attach File'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white60,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_noteTitleController.text.trim().isEmpty) {
                                  return;
                                }
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
                                  localAttachmentPaths: _attachedFilePaths,
                                  createdAt:
                                      existing?.createdAt ??
                                      DateTime.now().millisecondsSinceEpoch,
                                  updatedAt:
                                      DateTime.now().millisecondsSinceEpoch,
                                );
                                if (existing == null) {
                                  ref
                                      .read(notesProvider.notifier)
                                      .addNote(note);
                                } else {
                                  ref
                                      .read(notesProvider.notifier)
                                      .editNote(note);
                                }
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5B5FEF),
                                      Color(0xFF8151EB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF5B5FEF,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'Save Note',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = ref.watch(activeSemesterProvider);
    final notes = ref.watch(notesProvider);

    if (activeSem == null) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      color: Colors.white24,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Active Semester',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please activate a semester in Profile settings first.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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

    // Sort: favorites first, then by updatedAt
    filteredNotes.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              Text(
                '${semesterNotes.length} notes this semester',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _showAddNoteSheet(activeSem.id, null),
                child: GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: GlassTextField(
                controller: _searchController,
                labelText: 'Search by title, content, or tag...',
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Notes list
            Expanded(
              child: filteredNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 56,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            query.isEmpty ? 'No Notes Yet' : 'No Results Found',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            query.isEmpty
                                ? 'Tap + to capture your first note.'
                                : 'Try a different search term.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 13,
                            ),
                          ),
                          if (query.isEmpty) ...[
                            const SizedBox(height: 28),
                            GestureDetector(
                              onTap: () =>
                                  _showAddNoteSheet(activeSem.id, null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5B5FEF),
                                      Color(0xFF8151EB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF5B5FEF,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Create First Note',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return _NoteCard(
                          note: note,
                          onTap: () => _showAddNoteSheet(activeSem.id, note),
                          onFavorite: () => ref
                              .read(notesProvider.notifier)
                              .toggleFavorite(note.id),
                          onDelete: () => ref
                              .read(notesProvider.notifier)
                              .deleteNote(note.id),
                          onAttachmentTap: _previewAttachment,
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

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final ValueChanged<String> onAttachmentTap;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
    required this.onAttachmentTap,
  });

  static const _tagColors = [
    Color(0xFF5B5FEF),
    Color(0xFF10B981),
    Color(0xFF7BD0FF),
    Color(0xFFF59E0B),
    Color(0xFF8151EB),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isFavorite)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.star_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 16,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onFavorite,
                    child: Icon(
                      note.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: note.isFavorite
                          ? const Color(0xFFF59E0B)
                          : Colors.white24,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.localAttachmentPaths.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.localAttachmentPaths.map((path) {
                    final isPdf = path.toLowerCase().endsWith('.pdf');
                    return GestureDetector(
                      onTap: () => onAttachmentTap(path),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPdf ? Icons.picture_as_pdf : Icons.photo,
                              size: 12,
                              color: isPdf
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF7BD0FF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              path,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags.asMap().entries.map((e) {
                    final color = _tagColors[e.key % _tagColors.length];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '#${e.value}',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
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
  }
}
