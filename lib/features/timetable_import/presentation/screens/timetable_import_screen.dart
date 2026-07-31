import 'package:flutter/material.dart';
import 'package:trackx/features/timetable_import/domain/models/timetable_import_models.dart';
import 'package:trackx/features/timetable_import/domain/services/ocr_service.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';
import 'package:trackx/theme/app_theme.dart';

class TimetableImportScreen extends StatefulWidget {
  const TimetableImportScreen({super.key});

  @override
  State<TimetableImportScreen> createState() => _TimetableImportScreenState();
}

class _TimetableImportScreenState extends State<TimetableImportScreen> {
  final _ocrService = OcrService();
  final _textController = TextEditingController(
    text:
        'Monday\n09:15-10:15 Math Room302 Prof.Rao\n10:15-11:15 Physics Room304 Prof.Sen\n\nWednesday\n11:15-12:15 Chemistry Room101 Prof.Das',
  );

  List<DetectedTimetableEntry> _entries = [];
  bool _isProcessing = false;

  void _runParser() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 500), () {
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

  void _importTimetable() {
    if (_entries.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timetable imported successfully!')),
    );
    Navigator.pop(context);
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
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Paste your raw text, OCR dump, or select a timetable structure below to extract periods and times.',
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
                  if (_isProcessing)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentPurple,
                      ),
                    )
                  else
                    GlassPrimaryButton(
                      text: 'Extract & Parse Timetable',
                      onPressed: _runParser,
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
                                  labelStyle: TextStyle(color: Colors.white70),
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
                                  labelStyle: TextStyle(color: Colors.white70),
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
              GlassPrimaryButton(
                text: 'Save to My Timetable',
                onPressed: _importTimetable,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
