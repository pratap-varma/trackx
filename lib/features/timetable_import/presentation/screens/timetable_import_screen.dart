import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/features/timetable_import/domain/models/timetable_import_models.dart';
import 'package:trackx/features/timetable_import/domain/services/ocr_service.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class TimetableImportScreen extends ConsumerStatefulWidget {
  const TimetableImportScreen({super.key});

  @override
  ConsumerState<TimetableImportScreen> createState() =>
      _TimetableImportScreenState();
}

class _TimetableImportScreenState extends ConsumerState<TimetableImportScreen>
    with SingleTickerProviderStateMixin {
  final _ocrService = OcrService();
  final _textController = TextEditingController();

  List<DetectedTimetableEntry> _entries = [];
  bool _isProcessing = false;
  bool _isScanningImage = false;
  String _scanningStatus = '';

  int _weekdayToInt(String weekday) {
    final day = weekday.trim().toLowerCase();
    if (day.startsWith('mon')) return 1;
    if (day.startsWith('tue')) return 2;
    if (day.startsWith('wed')) return 3;
    if (day.startsWith('thu')) return 4;
    if (day.startsWith('fri')) return 5;
    if (day.startsWith('sat')) return 6;
    if (day.startsWith('sun')) return 7;
    return 1;
  }

  int _timeToMinutes(String timeStr) {
    final clean = timeStr.trim().replaceAll(RegExp(r'[a-zA-Z\s]'), '');
    final parts = clean.split(':');
    if (parts.length >= 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 60 + minutes;
    }
    return 0;
  }

  void _runParser() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      final parsed = _ocrService.parseTimetableText(_textController.text);
      setState(() {
        _entries = parsed;
        _isProcessing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Parsed ${_entries.length} entries successfully! Please review.',
          ),
        ),
      );
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await _processImageBytes(
          bytes,
          source == ImageSource.camera ? 'Camera Photo' : 'Gallery Image',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to access camera/gallery: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _processImageBytes(file.bytes!, file.name);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick document: $e')),
        );
      }
    }
  }

  Future<void> _processImageBytes(Uint8List bytes, String sourceName) async {
    setState(() {
      _isScanningImage = true;
      _scanningStatus = 'Scanning $sourceName with Vision AI...';
    });

    final settings = ref.read(aiSettingsProvider);
    final detected = await _ocrService.scanTimetableImage(
      imageBytes: bytes,
      apiKey: settings.customApiKey,
    );

    if (mounted) {
      setState(() {
        _entries = detected;
        _isScanningImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recognized ${_entries.length} scheduled periods from timetable photo!',
          ),
        ),
      );
    }
  }

  void _showMediaSourceSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0E1628),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 18),
              const Text(
                'Import Timetable Image / PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how you would like to provide your timetable:',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Option 1: Camera
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B243B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF7BD0FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Take Photo from Camera',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Snap a clear picture of your printed timetable',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Gallery
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B243B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: Color(0xFFC0C1FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose from Photos / Gallery',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pick a screenshot or downloaded schedule image',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 3: Document / PDF
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B243B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFFFF8B94),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pick PDF / Document File',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select official timetable PDF from files',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importTimetable() async {
    if (_entries.isEmpty) return;

    final activeSem = ref.read(activeSemesterProvider);
    if (activeSem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select or create an active semester first inside Settings.',
          ),
        ),
      );
      return;
    }

    final subjectsRepo = ref.read(subjectRepositoryProvider.notifier);
    final subjectsList = ref.read(subjectRepositoryProvider);
    final timetableRepo = ref.read(timetableRepositoryProvider.notifier);

    setState(() => _isProcessing = true);

    try {
      final colorPresets = [
        AppTheme.accentPurple.toARGB32(),
        AppTheme.accentBlue.toARGB32(),
        AppTheme.accentGreen.toARGB32(),
        AppTheme.accentPink.toARGB32(),
        AppTheme.accentOrange.toARGB32(),
      ];

      int colorIdx = 0;

      for (final entry in _entries) {
        // 1. Resolve or Create Subject
        String subjectId = '';
        final existingSubject = subjectsList.cast<Subject?>().firstWhere(
          (s) =>
              s != null &&
              s.name.toLowerCase() == entry.subjectName.trim().toLowerCase(),
          orElse: () => null,
        );

        if (existingSubject != null) {
          subjectId = existingSubject.id;
        } else {
          final color = colorPresets[colorIdx % colorPresets.length];
          colorIdx++;

          final success = await subjectsRepo.addSubject(
            activeSem.id,
            entry.subjectName,
            entry.faculty.isNotEmpty ? entry.faculty : 'Prof. TBD',
            color,
            activeSem.attendanceTarget,
          );

          if (success) {
            final updatedList = ref.read(subjectRepositoryProvider);
            final newSub = updatedList.firstWhere(
              (s) =>
                  s.name.toLowerCase() ==
                  entry.subjectName.trim().toLowerCase(),
            );
            subjectId = newSub.id;
          } else {
            continue;
          }
        }

        // 2. Add Timetable Entry
        final dayOfWeek = _weekdayToInt(entry.weekday);
        final startMinutes = _timeToMinutes(entry.startTime);
        final endMinutes = _timeToMinutes(entry.endTime);
        final uid = ref.read(authRepositoryProvider).userProfile?.id ?? 'user';

        final newTimetableEntry = TimetableEntry(
          id: 'entry-${DateTime.now().millisecondsSinceEpoch}-${entry.weekday}-${entry.period}-${math.Random().nextInt(100)}',
          userId: uid,
          semesterId: activeSem.id,
          subjectId: subjectId,
          dayOfWeek: dayOfWeek,
          periodNumber: entry.period,
          startTime: startMinutes,
          endTime: endMinutes,
          room: entry.room,
          isEnabled: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await timetableRepo.addEntry(newTimetableEntry);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable imported successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to import timetable: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Import Timetable',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const Text(
                  'Paste raw text, OCR dump, or upload an image of your timetable to automatically populate periods, subjects, and past attendance records.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  child: Column(
                    children: [
                      GlassTextField(
                        controller: _textController,
                        labelText: 'Raw Timetable Text / OCR Output',
                        hintText: 'Paste grid details here...',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showMediaSourceSheet,
                              icon: const Icon(
                                Icons.photo_camera_back_rounded,
                                size: 18,
                              ),
                              label: const Text('Upload Photo / PDF'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassPrimaryButton(
                              text: 'Extract Text',
                              onPressed: _runParser,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_entries.isNotEmpty) ...[
                  const Text(
                    'Review Extracted Entries',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_entries.length, (idx) {
                    final item = _entries[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.weekday} - Period ${item.period}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _entries.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.subjectName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Subject',
                                      labelStyle: TextStyle(
                                        color: Colors.white70,
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      _entries[idx] = DetectedTimetableEntry(
                                        weekday: item.weekday,
                                        period: item.period,
                                        startTime: item.startTime,
                                        endTime: item.endTime,
                                        subjectName: val,
                                        faculty: item.faculty,
                                        room: item.room,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        '${item.startTime}-${item.endTime}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Time Slot',
                                      labelStyle: TextStyle(
                                        color: Colors.white70,
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final parts = val.split('-');
                                      if (parts.length == 2) {
                                        _entries[idx] = DetectedTimetableEntry(
                                          weekday: item.weekday,
                                          period: item.period,
                                          startTime: parts[0].trim(),
                                          endTime: parts[1].trim(),
                                          subjectName: item.subjectName,
                                          faculty: item.faculty,
                                          room: item.room,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  if (_isProcessing)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentPurple,
                      ),
                    )
                  else
                    GlassPrimaryButton(
                      text: 'Save & Auto-Assign Attendance',
                      onPressed: _importTimetable,
                    ),
                ],
              ],
            ),
            if (_isScanningImage)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scanner Graphic
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.accentPurple,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              size: 100,
                              color: Colors.white24,
                            ),
                          ),
                          // Scanner line animation
                          Positioned(
                            top: 0,
                            child:
                                Container(
                                      width: 236,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentPurple,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accentPurple
                                                .withValues(alpha: 0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(reverse: true),
                                    )
                                    .moveY(
                                      begin: 10,
                                      end: 230,
                                      duration: 1.5.seconds,
                                      curve: Curves.easeInOut,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _scanningStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This might take a moment...',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
