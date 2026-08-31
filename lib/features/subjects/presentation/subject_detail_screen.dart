import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/notes/providers/flashcard_provider.dart';
import 'package:trackx/features/notes/presentation/widgets/flashcard_preview_editor_sheet.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/shared/widgets/ai_thinking_indicator.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  String _filter = 'all';
  final _overrideController = TextEditingController();
  final _noteTitleController = TextEditingController();
  final _noteContentController = TextEditingController();
  final _noteTagsController = TextEditingController();

  @override
  void dispose() {
    _overrideController.dispose();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    _noteTagsController.dispose();
    super.dispose();
  }

  Future<void> _generateFlashcardsForNote(Note note, String subjectName) async {
    HapticFeedback.mediumImpact();
    final aiSettings = ref.read(aiSettingsProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: AiThinkingIndicator(
          label: 'Crafting AI Flashcards...',
        ),
      ),
    );

    try {
      final deck = await ref.read(flashcardsProvider.notifier).generateFromNote(
            note: note,
            apiKey: aiSettings.customApiKey,
            subjectName: subjectName,
          );
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        final savedDeck = await FlashcardPreviewEditorSheet.show(
          context,
          deck: deck,
        );
        if (savedDeck != null && mounted) {
          context.push('/flashcards/${savedDeck.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate flashcards: $e')),
        );
      }
    }
  }

  void _showAddNoteSheet({
    Note? existing,
    required String semesterId,
    required String subjectName,
  }) {
    HapticFeedback.lightImpact();
    if (existing != null) {
      _noteTitleController.text = existing.title;
      _noteContentController.text = existing.content;
      _noteTagsController.text = existing.tags.join(', ');
    } else {
      _noteTitleController.clear();
      _noteContentController.clear();
      _noteTagsController.clear();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: Color(0xFFC0C1FF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existing == null
                                      ? 'Take Subject Note'
                                      : 'Edit Note',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Linked to $subjectName',
                                  style: const TextStyle(
                                    color: Color(0xFF7BD0FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GlassTextField(
                        controller: _noteTitleController,
                        labelText: 'Title (e.g., Unit 2 Important Theorems)',
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _noteContentController,
                        labelText: 'Write your notes or key points...',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _noteTagsController,
                        labelText: 'Tags (comma separated, e.g. Exam, Formula)',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white60,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final title = _noteTitleController.text.trim();
                                final content = _noteContentController.text.trim();
                                if (title.isEmpty && content.isEmpty) return;

                                final rawTags = _noteTagsController.text
                                    .split(',')
                                    .map((t) => t.trim())
                                    .where((t) => t.isNotEmpty)
                                    .toList();

                                final authState = ref.read(authRepositoryProvider);
                                final userId = authState.userProfile?.id ?? 'guest';
                                final now = DateTime.now().millisecondsSinceEpoch;

                                if (existing != null) {
                                  ref.read(notesProvider.notifier).editNote(
                                        existing.copyWith(
                                          title: title.isEmpty ? 'Untitled Note' : title,
                                          content: content,
                                          tags: rawTags,
                                          updatedAt: now,
                                        ),
                                      );
                                } else {
                                  final note = Note(
                                    id: 'note_${DateTime.now().millisecondsSinceEpoch}',
                                    userId: userId,
                                    semesterId: semesterId,
                                    title: title.isEmpty ? 'Untitled Note' : title,
                                    content: content,
                                    subjectId: widget.subjectId,
                                    tags: rawTags,
                                    isFavorite: false,
                                    localAttachmentPaths: const [],
                                    createdAt: now,
                                    updatedAt: now,
                                  );
                                  ref.read(notesProvider.notifier).addNote(note);
                                }

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      existing != null
                                          ? 'Note updated successfully!'
                                          : 'Note added for $subjectName!',
                                    ),
                                    duration: const Duration(milliseconds: 1800),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(
                                      bottom: 24,
                                      left: 16,
                                      right: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5B5FEF).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    existing != null ? 'Update Note' : 'Save Note',
                                    style: const TextStyle(
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

  void _confirmDeleteNote(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Delete Note?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to remove "${note.title}"?',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final backup = note;
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Note deleted.'),
                          duration: const Duration(milliseconds: 2500),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.only(
                            bottom: 24,
                            left: 16,
                            right: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          action: SnackBarAction(
                            label: 'UNDO',
                            textColor: const Color(0xFF7BD0FF),
                            onPressed: () {
                              ref.read(notesProvider.notifier).addNote(backup);
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOverrideDialog(double currentTarget) {
    _overrideController.text = currentTarget.toInt().toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          borderRadius: 20,
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Override Target',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Set a custom attendance target for this subject.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: _overrideController,
                labelText: 'Target (%)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white60,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final val = double.tryParse(
                          _overrideController.text.trim(),
                        );
                        if (val != null && val >= 1 && val <= 100) {
                          final subjects = ref.read(subjectRepositoryProvider);
                          final sub = subjects.firstWhere(
                            (s) => s.id == widget.subjectId,
                          );
                          await ref
                              .read(subjectRepositoryProvider.notifier)
                              .editSubject(
                                sub.id,
                                sub.name,
                                sub.facultyName,
                                sub.colorValue,
                                val,
                              );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
  }

  void _confirmDeleteRecord(BuildContext context, dynamic rec) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1628),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Delete Record?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This attendance log will be permanently removed.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final backup = rec;
                      await ref
                          .read(attendanceRepositoryProvider.notifier)
                          .deleteAttendance(rec.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).clearSnackBars();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: const Text('Attendance record deleted.'),
                            duration: const Duration(milliseconds: 2000),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(
                              bottom: 24,
                              left: 16,
                              right: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: 'UNDO',
                              textColor: const Color(0xFF7BD0FF),
                              onPressed: () async {
                                await ref
                                    .read(attendanceRepositoryProvider.notifier)
                                    .insertRecord(backup);
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final subjectStatsList = stats.allSubjectStats
        .where((s) => s.subject.id == widget.subjectId)
        .toList();

    if (subjectStatsList.isEmpty) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(
            child: Text(
              'Subject not found',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final subStats = subjectStatsList.first;
    final sub = subStats.subject;
    final records = ref
        .watch(attendanceRepositoryProvider)
        .where((r) => r.subjectId == sub.id)
        .toList();

    final filteredRecords = records.where((r) {
      if (_filter == 'present') return r.status == 'present';
      if (_filter == 'absent') return r.status == 'absent';
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final allNotes = ref.watch(notesProvider);
    final subjectNotes = allNotes
        .where((n) => n.subjectId == widget.subjectId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final subjectColor = Color(sub.colorValue);
    final pct = subStats.percentage;
    final pctColor = pct >= subStats.target
        ? const Color(0xFF10B981)
        : pct >= 60
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    final riskLabel = subStats.riskLevel.toUpperCase();
    final riskColor = switch (subStats.riskLevel.toLowerCase()) {
      'safe' => const Color(0xFF10B981),
      'warning' => const Color(0xFFF59E0B),
      _ => const Color(0xFFEF4444),
    };

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
            onPressed: () => context.pop(),
          ),
          title: Text(
            sub.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFC0C1FF),
                size: 24,
              ),
              onPressed: () => _showAddNoteSheet(
                semesterId: sub.semesterId,
                subjectName: sub.name,
              ),
              tooltip: 'Take Subject Note',
            ),
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
              onPressed: () => _showOverrideDialog(subStats.target),
              tooltip: 'Override Target',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Hero stat card
            GlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Ring
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: CustomPaint(
                          painter: _AttendanceRingPainter(
                            progress: (pct / 100).clamp(0.0, 1.0),
                            color: pctColor,
                            subjectColor: subjectColor,
                          ),
                          child: Center(
                            child: Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: pctColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.facultyName.isNotEmpty
                                    ? sub.facultyName
                                    : 'Instructor Not Set',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                riskLabel,
                                style: TextStyle(
                                  color: riskColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _miniStat(
                                  subStats.presentCount.toString(),
                                  'Present',
                                  const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 16),
                                _miniStat(
                                  subStats.absentCount.toString(),
                                  'Absent',
                                  const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 16),
                                _miniStat(
                                  '${subStats.totalCount}',
                                  'Total',
                                  Colors.white54,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: ${subStats.target.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      if (subStats.safeBunks > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF10B981),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Can bunk ${subStats.safeBunks} more',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else if (subStats.requiredRecovery > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFEF4444),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Need ${subStats.requiredRecovery} more',
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'At threshold',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick Mark Attendance Card for Today
            Builder(
              builder: (context) {
                final now = DateTime.now();
                final todayRecs = records.where((r) =>
                    r.date.year == now.year &&
                    r.date.month == now.month &&
                    r.date.day == now.day).toList();
                final todayRecord = todayRecs.firstOrNull;
                final isMarkedToday = todayRecord != null;
                final isPresentToday = todayRecord?.status == 'present';

                final authState = ref.watch(authRepositoryProvider);
                final userId = authState.userProfile?.id ?? 'user';

                return GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  borderColor: isMarkedToday
                      ? (isPresentToday
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : const Color(0xFFEF4444).withValues(alpha: 0.4))
                      : Colors.white.withValues(alpha: 0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isMarkedToday
                                ? (isPresentToday
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded)
                                : Icons.today_rounded,
                            size: 20,
                            color: isMarkedToday
                                ? (isPresentToday
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                : const Color(0xFF7BD0FF),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Today's Attendance",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isMarkedToday
                                    ? (isPresentToday
                                        ? 'Logged as Present'
                                        : 'Logged as Absent')
                                    : 'Not logged yet today',
                                style: TextStyle(
                                  color: isMarkedToday
                                      ? (isPresentToday
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: isMarkedToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isMarkedToday)
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            await ref
                                .read(attendanceRepositoryProvider.notifier)
                                .deleteAttendance(todayRecord.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Cleared today's attendance record."),
                                  duration: const Duration(milliseconds: 1500),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Text(
                              'Undo',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                await ref
                                    .read(attendanceRepositoryProvider.notifier)
                                    .markAttendance(
                                      userId: userId,
                                      semesterId: sub.semesterId,
                                      subjectId: sub.id,
                                      date: DateTime.now(),
                                      status: 'absent',
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Marked Absent for ${sub.name} today'),
                                      duration: const Duration(milliseconds: 1500),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Text(
                                  'Absent',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                await ref
                                    .read(attendanceRepositoryProvider.notifier)
                                    .markAttendance(
                                      userId: userId,
                                      semesterId: sub.semesterId,
                                      subjectId: sub.id,
                                      date: DateTime.now(),
                                      status: 'present',
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Marked Present for ${sub.name} today!'),
                                      duration: const Duration(milliseconds: 1500),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Text(
                                  'Present',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),

            // Subject Heatmap Quick Action Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/attendance/heatmap?subjectId=${sub.id}');
              },
              borderRadius: BorderRadius.circular(14),
              child: GlassContainer(
                borderRadius: 14,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_view_month_rounded,
                            size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 10),
                        Text(
                          'View Subject Heatmap Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Subject Notes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sticky_note_2_rounded,
                        color: Color(0xFFC0C1FF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Subject Notes (${subjectNotes.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showAddNoteSheet(
                    semesterId: sub.semesterId,
                    subjectName: sub.name,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B5FEF).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Take Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (subjectNotes.isEmpty)
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B5FEF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.note_add_outlined,
                        color: Color(0xFF7BD0FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No notes for this subject yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tap "Take Note" to write lecture summaries or key formulas.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...subjectNotes.map((note) {
                final noteDt = DateTime.fromMillisecondsSinceEpoch(
                  note.updatedAt > 0 ? note.updatedAt : note.createdAt,
                );
                final formattedDate =
                    DateFormat('MMM d • hh:mm a').format(noteDt);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (note.isFavorite)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFF59E0B),
                                        size: 15,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(notesProvider.notifier)
                                        .toggleFavorite(note.id);
                                  },
                                  child: Icon(
                                    note.isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: note.isFavorite
                                        ? const Color(0xFFF59E0B)
                                        : Colors.white30,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => _showAddNoteSheet(
                                    existing: note,
                                    semesterId: sub.semesterId,
                                    subjectName: sub.name,
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF7BD0FF),
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () =>
                                      _confirmDeleteNote(context, note),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white30,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (note.content.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            note.content,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (note.tags.isNotEmpty)
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: note.tags.take(3).map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5B5FEF)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF5B5FEF)
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        '#$tag',
                                        style: const TextStyle(
                                          color: Color(0xFFC0C1FF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () =>
                                _generateFlashcardsForNote(note, sub.name),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B5FEF)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF5B5FEF)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12,
                                    color: Color(0xFFC0C1FF),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Study Flashcards',
                                    style: TextStyle(
                                      color: Color(0xFFC0C1FF),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
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
              }),
            const SizedBox(height: 24),

            // Filter + Log header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Log',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: ['all', 'present', 'absent'].map((f) {
                    final isActive = _filter == f;
                    final fColor = switch (f) {
                      'present' => const Color(0xFF10B981),
                      'absent' => const Color(0xFFEF4444),
                      _ => Colors.white,
                    };
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? fColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? fColor.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          f == 'all'
                              ? 'All'
                              : f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(
                            color: isActive ? fColor : Colors.white30,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (filteredRecords.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        color: Colors.white.withValues(alpha: 0.15),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filter == 'all'
                            ? 'No attendance logged yet'
                            : 'No $_filter records',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredRecords.map((rec) {
                final isEditable = AttendanceRepository.canEditAttendance(
                  rec,
                  DateTime.now(),
                );
                final isPresent = rec.status == 'present';
                final statusColor = isPresent
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444);
                
                final markedTimestamp = rec.updatedAt > 0 ? rec.updatedAt : rec.createdAt;
                final markedTime = markedTimestamp > 0
                    ? DateTime.fromMillisecondsSinceEpoch(markedTimestamp)
                    : rec.date;
                final timeFormatted = DateFormat('hh:mm a').format(markedTime);
                final dateFormatted = DateFormat('EEE, MMM d, yyyy').format(rec.date);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Status dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFormatted,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: const Color(0xFF7BD0FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Marked at $timeFormatted',
                                    style: const TextStyle(
                                      color: Color(0xFF7BD0FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (rec.periodNumber != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '• Period ${rec.periodNumber}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rec.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isEditable)
                          GestureDetector(
                            onTap: () => _confirmDeleteRecord(context, rec),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white.withValues(alpha: 0.25),
                              size: 18,
                            ),
                          )
                        else
                          Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.12),
                            size: 15,
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  static Widget _miniStat(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }
}

class _AttendanceRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color subjectColor;

  _AttendanceRingPainter({
    required this.progress,
    required this.color,
    required this.subjectColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1F2A3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_AttendanceRingPainter old) => old.progress != progress;
}
