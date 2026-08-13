import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/timetable/providers/timetable_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  final _roomController = TextEditingController();
  final _notesController = TextEditingController();
  int _startHour = 9;
  int _startMin = 15;
  int _endHour = 10;
  int _endMin = 15;

  @override
  void dispose() {
    _roomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showEditSheet(
    String activeSemId,
    int day,
    int period,
    TimetableEntry? existing,
  ) {
    String? selectedSubId = existing?.subjectId;
    if (existing != null) {
      _roomController.text = existing.room ?? '';
      _notesController.text = existing.notes ?? '';
      _startHour = existing.startTime ~/ 60;
      _startMin = existing.startTime % 60;
      _endHour = existing.endTime ~/ 60;
      _endMin = existing.endTime % 60;
    } else {
      _roomController.clear();
      _notesController.clear();
      // Default to period hours (e.g. Period 1 defaults to 9:15 - 10:15)
      _startHour = 9 + period - 1;
      _startMin = 15;
      _endHour = _startHour + 1;
      _endMin = 15;
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
                    existing == null
                        ? 'Schedule Period $period'
                        : 'Edit Period $period',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subject Select
                  DropdownButtonFormField<String>(
                    value: selectedSubId,
                    dropdownColor: AppTheme.darkBgBase,
                    decoration: const InputDecoration(
                      labelText: 'Select Subject',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: subjects.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub.id,
                        child: Text(sub.name),
                      );
                    }).toList(),
                    onChanged: (val) => selectedSubId = val,
                  ),
                  const SizedBox(height: 16),

                  // Room Input
                  GlassTextField(
                    controller: _roomController,
                    labelText: 'Classroom / Lab Room',
                  ),
                  const SizedBox(height: 16),

                  // Notes Input
                  GlassTextField(
                    controller: _notesController,
                    labelText: 'Short notes (e.g. Odd weeks only)',
                  ),
                  const SizedBox(height: 24),

                  // Save Action
                  GlassPrimaryButton(
                    text: 'Save Schedule',
                    onPressed: () async {
                      if (selectedSubId == null) return;

                      final entry = TimetableEntry(
                        id:
                            existing?.id ??
                            'entry-${DateTime.now().millisecondsSinceEpoch}',
                        userId: existing?.userId ?? 'guest',
                        semesterId: activeSemId,
                        subjectId: selectedSubId!,
                        dayOfWeek: day,
                        periodNumber: period,
                        startTime: _startHour * 60 + _startMin,
                        endTime: _endHour * 60 + _endMin,
                        room: _roomController.text.trim().isNotEmpty
                            ? _roomController.text.trim()
                            : null,
                        notes: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : null,
                        isEnabled: existing?.isEnabled ?? true,
                        createdAt:
                            existing?.createdAt ??
                            DateTime.now().millisecondsSinceEpoch,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      );

                      final error = existing == null
                          ? await ref
                                .read(timetableRepositoryProvider.notifier)
                                .addEntry(entry)
                          : await ref
                                .read(timetableRepositoryProvider.notifier)
                                .updateEntry(entry);

                      if (error != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                        }
                      } else {
                        if (context.mounted) Navigator.pop(context);
                      }
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
    final selectedDay = ref.watch(selectedTimetableDayProvider);
    final allEntries = ref.watch(activeSemesterTimetableProvider);
    final subjects = ref.watch(subjectRepositoryProvider);

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    if (activeSem == null) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(
            child: Text(
              'Please activate a semester in Profile settings first.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Timetable',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload_rounded, color: Colors.white),
              tooltip: 'Import Timetable',
              onPressed: () => context.push('/import-timetable'),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: () {
                // Copy day simple prompt
                showDialog(
                  context: context,
                  builder: (context) {
                    int destDay = 2;
                    return AlertDialog(
                      backgroundColor: Colors.transparent,
                      content: GlassContainer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Copy ${weekdays[selectedDay - 1]} Schedule',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: destDay,
                              dropdownColor: AppTheme.darkBgBase,
                              decoration: const InputDecoration(
                                labelText: 'Copy To Day',
                              ),
                              items: List.generate(6, (i) => i + 1).map((d) {
                                return DropdownMenuItem<int>(
                                  value: d,
                                  child: Text(weekdays[d - 1]),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) destDay = val;
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                await ref
                                    .read(timetableRepositoryProvider.notifier)
                                    .copyDay(
                                      activeSem.id,
                                      selectedDay,
                                      destDay,
                                    );
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Copy Now'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () async {
                await ref
                    .read(timetableRepositoryProvider.notifier)
                    .clearDay(activeSem.id, selectedDay);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Weekday tabs row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(6, (index) {
                  final dayVal = index + 1;
                  final isSelected = selectedDay == dayVal;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(selectedTimetableDayProvider.notifier).state =
                            dayVal,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentPurple.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentPurple
                              : Colors.white12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        weekdays[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Timetable period list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 120,
                ),
                itemCount: 6,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final period = index + 1;
                  final dayEntries = allEntries
                      .where(
                        (e) =>
                            e.dayOfWeek == selectedDay &&
                            e.periodNumber == period,
                      )
                      .toList();
                  final entry = dayEntries.isNotEmpty ? dayEntries.first : null;
                  final sub = entry != null
                      ? subjects
                            .where((s) => s.id == entry.subjectId)
                            .firstOrNull
                      : null;

                  return GestureDetector(
                    onTap: () => _showEditSheet(
                      activeSem.id,
                      selectedDay,
                      period,
                      entry,
                    ),
                    child: GlassContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Period $period',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sub?.name ?? 'Free Period',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              if (entry != null)
                                Text(
                                  '${entry.startTimeDisplay} - ${entry.endTimeDisplay} ${entry.room != null ? "â€¢ Rm " + entry.room! : ""}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                          if (entry != null)
                            Row(
                              children: [
                                Switch(
                                  value: entry.isEnabled,
                                  onChanged: (val) {
                                    ref
                                        .read(
                                          timetableRepositoryProvider.notifier,
                                        )
                                        .setEnabled(entry.id, val);
                                  },
                                  activeColor: AppTheme.accentPurple,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () => ref
                                      .read(
                                        timetableRepositoryProvider.notifier,
                                      )
                                      .deleteEntry(entry.id),
                                ),
                              ],
                            )
                          else
                            const Icon(
                              Icons.add_circle_outline,
                              color: Colors.white38,
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
