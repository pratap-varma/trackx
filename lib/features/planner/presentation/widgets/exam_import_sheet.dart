import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/features/timetable_import/domain/models/timetable_import_models.dart';
import 'package:trackx/features/timetable_import/domain/services/ocr_service.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class ExamImportSheet extends ConsumerStatefulWidget {
  const ExamImportSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExamImportSheet(),
    );
  }

  @override
  ConsumerState<ExamImportSheet> createState() => _ExamImportSheetState();
}

class _ExamImportSheetState extends ConsumerState<ExamImportSheet> {
  final _ocrService = OcrService();
  bool _isScanning = false;
  String _scanningStatus = '';
  List<DetectedExamEntry> _detectedExams = [];
  final Set<int> _selectedIndices = {};

  void _showEditExamDialog(int index) {
    HapticFeedback.selectionClick();
    final entry = _detectedExams[index];
    DateTime selectedDate = entry.examDate;
    String selectedType = entry.examType;
    final titleCtrl = TextEditingController(text: entry.title);
    final subjectCtrl = TextEditingController(text: entry.subjectName);
    final startCtrl = TextEditingController(text: entry.startTime);
    final endCtrl = TextEditingController(text: entry.endTime);
    final roomCtrl = TextEditingController(text: entry.room);
    final syllabusCtrl = TextEditingController(text: entry.syllabus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0E1628),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Exam Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Interactive Date Picker
                  const Text(
                    'EXAMINATION DATE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF5B5FEF).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Color(0xFF7BD0FF), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Change Date',
                              style: TextStyle(
                                color: Color(0xFF7BD0FF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Exam Type Selector
                  const Text(
                    'EXAM TYPE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Midterm', 'Final', 'Quiz', 'Lab Practical', 'Internal'].map((t) {
                        final isSelected = selectedType.toLowerCase() == t.toLowerCase();
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedType = t),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF5B5FEF) : const Color(0xFF131A2B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.white12,
                              ),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Exam Title & Subject Name
                  GlassTextField(
                    controller: titleCtrl,
                    labelText: 'Exam Title',
                    hintText: 'e.g. Midterm Examination',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: subjectCtrl,
                    labelText: 'Subject Name',
                    hintText: 'e.g. Data Structures & Algorithms',
                  ),
                  const SizedBox(height: 14),

                  // 4. Timings
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: startCtrl,
                          labelText: 'Start Time',
                          hintText: 'e.g. 10:00 AM',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassTextField(
                          controller: endCtrl,
                          labelText: 'End Time',
                          hintText: 'e.g. 01:00 PM',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Room & Syllabus
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: roomCtrl,
                          labelText: 'Room / Hall',
                          hintText: 'e.g. DE-12',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassTextField(
                          controller: syllabusCtrl,
                          labelText: 'Syllabus / Units',
                          hintText: 'e.g. Units 1, 2 & 3',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Save Changes Button
                  GestureDetector(
                    onTap: () {
                      final newTitle = titleCtrl.text.trim();
                      final newSubject = subjectCtrl.text.trim();
                      if (newTitle.isNotEmpty && newSubject.isNotEmpty) {
                        setState(() {
                          _detectedExams[index] = DetectedExamEntry(
                            title: newTitle,
                            subjectName: newSubject,
                            examType: selectedType,
                            examDate: selectedDate,
                            startTime: startCtrl.text.trim(),
                            endTime: endCtrl.text.trim(),
                            room: roomCtrl.text.trim(),
                            syllabus: syllabusCtrl.text.trim(),
                          );
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        // Success SnackBar removed as requested
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
        await _processBytes(
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
          await _processBytes(file.bytes!, file.name);
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

  Future<void> _processBytes(Uint8List bytes, String sourceName) async {
    setState(() {
      _isScanning = true;
      _scanningStatus = 'Scanning $sourceName with Exam Vision AI...';
    });

    final settings = ref.read(aiSettingsProvider);
    final exams = await _ocrService.scanExamTimetableImage(
      imageBytes: bytes,
      apiKey: settings.customApiKey,
    );

    if (mounted) {
      setState(() {
        _detectedExams = exams;
        _selectedIndices.clear();
        for (int i = 0; i < exams.length; i++) {
          _selectedIndices.add(i);
        }
        _isScanning = false;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _importSelectedExams() async {
    if (_selectedIndices.isEmpty) return;

    final activeSem = ref.read(activeSemesterProvider);
    final subjectsRepo = ref.read(subjectRepositoryProvider.notifier);
    final subjectsList = ref.read(subjectRepositoryProvider);
    final examsNotifier = ref.read(examsProvider.notifier);

    final colorPresets = [
      AppTheme.accentPurple.toARGB32(),
      AppTheme.accentBlue.toARGB32(),
      AppTheme.accentGreen.toARGB32(),
      AppTheme.accentPink.toARGB32(),
      AppTheme.accentOrange.toARGB32(),
    ];

    int colorIdx = 0;
    int importedCount = 0;

    for (final index in _selectedIndices) {
      if (index >= _detectedExams.length) continue;
      final detected = _detectedExams[index];

      // 1. Map or create Subject
      String subjectId = '';
      final existingSub = subjectsList.cast<Subject?>().firstWhere(
        (s) =>
            s != null &&
            s.name.toLowerCase() == detected.subjectName.trim().toLowerCase(),
        orElse: () => null,
      );

      if (existingSub != null) {
        subjectId = existingSub.id;
      } else if (activeSem != null) {
        final color = colorPresets[colorIdx % colorPresets.length];
        colorIdx++;
        final success = await subjectsRepo.addSubject(
          activeSem.id,
          detected.subjectName,
          'Exam Faculty',
          color,
          activeSem.attendanceTarget,
        );
        if (success) {
          final updatedSubs = ref.read(subjectRepositoryProvider);
          final newSub = updatedSubs.firstWhere(
            (s) =>
                s.name.toLowerCase() ==
                detected.subjectName.trim().toLowerCase(),
          );
          subjectId = newSub.id;
        }
      }

      // 2. Add Exam
      final newExam = Exam(
        id: 'exam-${DateTime.now().millisecondsSinceEpoch}-$index',
        userId: 'user',
        semesterId: activeSem?.id ?? 'sem-1',
        subjectId: subjectId.isNotEmpty ? subjectId : 'sub-1',
        title: detected.title,
        examType: detected.examType,
        examDate: detected.examDate,
        startTime: detected.startTime,
        endTime: detected.endTime.isNotEmpty ? detected.endTime : null,
        syllabus: detected.syllabus,
        preparationProgress: 0.0,
        notes: detected.room.isNotEmpty ? 'Room: ${detected.room}' : null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      examsNotifier.addExam(newExam);
      importedCount++;
    }

    if (mounted) {
      Navigator.pop(context);
      HapticFeedback.heavyImpact();
      if (importedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              'Successfully imported $importedCount exam(s) into your schedule!',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0E1628),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Exam Date-Sheet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Import Midterm or Final Exam PDF / Photos',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Upload Option Buttons
          if (_detectedExams.isEmpty && !_isScanning) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131A2B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  // Camera Button
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B243B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: Color(0xFF7BD0FF),
                            size: 22,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Take Photo of Exam Schedule',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Capture printed exam schedule notification',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Gallery Button
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B243B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.photo_library_rounded,
                            color: Color(0xFFC0C1FF),
                            size: 22,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose from Photos / Gallery',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pick screenshot of college exam notice',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // PDF Document Button
                  GestureDetector(
                    onTap: _pickDocument,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B243B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFFFF8B94),
                            size: 22,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pick Official Exam PDF File',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Select university date-sheet PDF document',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Scanning Animation
          if (_isScanning) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5B5FEF),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _scanningStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Analyzing examination dates, subject codes, and timings...',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Review Detected Exams List
          if (_detectedExams.isNotEmpty && !_isScanning) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DETECTED EXAMINATIONS (${_selectedIndices.length}/${_detectedExams.length})',
                  style: const TextStyle(
                    color: Color(0xFFC0C1FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedIndices.length == _detectedExams.length) {
                        _selectedIndices.clear();
                      } else {
                        _selectedIndices.clear();
                        for (int i = 0; i < _detectedExams.length; i++) {
                          _selectedIndices.add(i);
                        }
                      }
                    });
                  },
                  child: Text(
                    _selectedIndices.length == _detectedExams.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                      color: Color(0xFF7BD0FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: _detectedExams.length,
                itemBuilder: (context, index) {
                  final ex = _detectedExams[index];
                  final isSelected = _selectedIndices.contains(index);
                  final dateFormatted = DateFormat(
                    'EEE, MMM d, yyyy',
                  ).format(ex.examDate);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndices.remove(index);
                          } else {
                            _selectedIndices.add(index);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A2B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(
                                    0xFF5B5FEF,
                                  ).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF5B5FEF),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIndices.add(index);
                                  } else {
                                    _selectedIndices.remove(index);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5B5FEF,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          ex.examType.toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFFC0C1FF),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateFormatted,
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ex.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${ex.startTime}${ex.endTime.isNotEmpty ? ' - ${ex.endTime}' : ''}${ex.room.isNotEmpty ? ' • Room ${ex.room}' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  if (ex.syllabus.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Syllabus: ${ex.syllabus}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showEditExamDialog(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B243B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF7BD0FF).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_calendar_rounded,
                                      color: Color(0xFF7BD0FF),
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Color(0xFF7BD0FF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
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
                },
              ),
            ),
            const SizedBox(height: 12),

            // Import Action Button
            GestureDetector(
              onTap: _selectedIndices.isNotEmpty ? _importSelectedExams : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _selectedIndices.isNotEmpty
                      ? const LinearGradient(
                          colors: [Color(0xFF5B5FEF), Color(0xFF8151EB)],
                        )
                      : null,
                  color: _selectedIndices.isEmpty
                      ? Colors.white.withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Schedule ${_selectedIndices.length} Exams into Planner',
                    style: TextStyle(
                      color: _selectedIndices.isNotEmpty
                          ? Colors.white
                          : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
