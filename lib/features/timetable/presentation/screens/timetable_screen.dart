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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFDEE2F4) : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final dropdownBg = isDark ? const Color(0xFF131A2B) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final subjects = ref
                .watch(subjectRepositoryProvider)
                .where((s) => s.semesterId == activeSemId && !s.isArchived)
                .toList();

            final startFormatted =
                '${_startHour.toString().padLeft(2, '0')}:${_startMin.toString().padLeft(2, '0')}';
            final endFormatted =
                '${_endHour.toString().padLeft(2, '0')}:${_endMin.toString().padLeft(2, '0')}';

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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subject Select
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubId,
                        dropdownColor: dropdownBg,
                        decoration: InputDecoration(
                          labelText: 'Select Subject',
                          labelStyle: TextStyle(color: subtextColor),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: textColor),
                        items: subjects.map((sub) {
                          return DropdownMenuItem<String>(
                            value: sub.id,
                            child: Text(sub.name, style: TextStyle(color: textColor)),
                          );
                        }).toList(),
                        onChanged: (val) => selectedSubId = val,
                      ),
                      const SizedBox(height: 16),

                      // Time Pickers Row
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: _startHour,
                                    minute: _startMin,
                                  ),
                                );
                                if (picked != null) {
                                  setSheetState(() {
                                    _startHour = picked.hour;
                                    _startMin = picked.minute;
                                    if (_endHour < _startHour ||
                                        (_endHour == _startHour &&
                                            _endMin <= _startMin)) {
                                      _endHour = (_startHour + 1) % 24;
                                      _endMin = _startMin;
                                    }
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Time',
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      startFormatted,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: _endHour,
                                    minute: _endMin,
                                  ),
                                );
                                if (picked != null) {
                                  setSheetState(() {
                                    _endHour = picked.hour;
                                    _endMin = picked.minute;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Time',
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      endFormatted,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
                                'entry-${DateTime.now().microsecondsSinceEpoch}',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSem = ref.watch(activeSemesterProvider);
    final selectedDay = ref.watch(selectedTimetableDayProvider);
    final allEntries = ref.watch(activeSemesterTimetableProvider);
    final subjects = ref.watch(subjectRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFDEE2F4) : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final mutedTextColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    if (activeSem == null) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              'Please activate a semester in Profile settings first.',
              style: TextStyle(color: subtextColor),
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
          title: Text(
            'Timetable',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.file_upload_rounded, color: textColor),
              tooltip: 'Import Timetable',
              onPressed: () => context.push('/import-timetable'),
            ),
            IconButton(
              icon: Icon(Icons.copy, color: textColor),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: destDay,
                              dropdownColor: isDark ? const Color(0xFF131A2B) : Colors.white,
                              decoration: const InputDecoration(
                                labelText: 'Copy To Day',
                              ),
                              items: List.generate(6, (i) => i + 1).map((d) {
                                return DropdownMenuItem<int>(
                                  value: d,
                                  child: Text(weekdays[d - 1], style: TextStyle(color: textColor)),
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
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentPurple
                              : (isDark ? Colors.white12 : Colors.black12),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        weekdays[index],
                        style: TextStyle(
                          color: isSelected ? (isDark ? Colors.white : AppTheme.accentPurple) : subtextColor,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Period $period',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sub?.name ?? 'Free Period',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                if (entry != null)
                                  Text(
                                    '${entry.startTimeDisplay} - ${entry.endTimeDisplay} ${entry.room != null ? "• Rm ${entry.room}" : ""}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtextColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                  activeThumbColor: AppTheme.accentPurple,
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
                            Icon(
                              Icons.add_circle_outline,
                              color: mutedTextColor,
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
