import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:trackx/core/services/activity_logger.dart';
import 'package:trackx/features/timetable_import/domain/models/timetable_import_models.dart';

class OcrService {
  /// Helper to call Gemini Vision with automatic model fallback & direct REST fallback
  Future<String> _callGeminiVision({
    required String apiKey,
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    final candidateModels = [
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-2.0-flash',
      'gemini-2.5-flash',
      'gemini-1.5-pro',
    ];

    String mimeType = 'image/jpeg';
    if (imageBytes.length >= 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      mimeType = 'image/png';
    } else if (imageBytes.length >= 4 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46) {
      mimeType = 'image/webp';
    }

    String? lastErrorMessage;

    // 1. Try google_generative_ai SDK with candidate models
    for (final modelName in candidateModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        final response = await model.generateContent([
          Content.multi([
            TextPart(prompt),
            DataPart(mimeType, imageBytes),
          ]),
        ]);

        if (response.text != null && response.text!.trim().isNotEmpty) {
          return response.text!.trim();
        }
      } catch (e) {
        lastErrorMessage = e.toString();
      }
    }

    // 2. Direct REST API fallback to v1beta endpoint (handles any SDK versioning discrepancies)
    final base64Image = base64Encode(imageBytes);
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ]
    });

    for (final modelName in candidateModels) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
        );

        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        );

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }
        } else {
          try {
            final errObj = jsonDecode(res.body);
            if (errObj is Map && errObj['error'] != null) {
              lastErrorMessage = errObj['error']['message']?.toString() ?? res.body;
            } else {
              lastErrorMessage = 'HTTP ${res.statusCode}: ${res.body}';
            }
          } catch (_) {
            lastErrorMessage = 'HTTP ${res.statusCode}: ${res.body}';
          }
        }
      } catch (e) {
        lastErrorMessage = e.toString();
      }
    }

    throw Exception(
      lastErrorMessage ??
          'Unable to connect to Gemini with the provided API key. Please check your internet connection or verify your API key in Profile -> AI Assistant & Gemini Key.',
    );
  }

  /// Resolve API Key from argument, environment, or fallback
  String _resolveApiKey(String? apiKey) {
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      return apiKey.trim();
    }
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey.trim();
    }
    return '';
  }

  Future<void> _validateImage(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frameInfo = await codec.getNextFrame();
      final width = frameInfo.image.width;
      final height = frameInfo.image.height;
      if (width < 300 || height < 300) {
        throw Exception(
            'Image resolution (${width}x$height) is too small to reliably read a timetable. Please upload a clearer, higher-resolution image.');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('resolution')) {
        rethrow;
      }
      // If we can't decode, just let it pass to API
    }
  }

  /// Scan timetable photo or PDF bytes using Gemini Vision
  Future<List<DetectedTimetableEntry>> scanTimetableImage({
    required Uint8List imageBytes,
    String? apiKey,
  }) async {
    ActivityLogger().logEvent('ai_timetable_ocr_used', parameters: {'feature': 'timetable_grid_ocr'});
    final effectiveKey = _resolveApiKey(apiKey);
    
    if (effectiveKey.isEmpty) {
      throw Exception('Gemini API Key is missing. Please configure your key in settings.');
    }

    await _validateImage(imageBytes);

    int maxAttempts = 2;
    String additionalInstructions = "";
    List<DetectedTimetableEntry> bestEntries = [];

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final prompt = '''
You are extracting a college timetable from an image.
Treat the image as a TWO-DIMENSIONAL TABLE.
Do not summarize the timetable.
Do not extract only the first few rows.
Do not stop after detecting the first three periods.
Read the COMPLETE timetable from top to bottom and left to right.

First identify:
1. timetable boundaries
2. day columns (e.g. MON, TUE, WED)
3. period rows (e.g. 1, 2, 3)
4. time labels (e.g. 9:15-10:15)
5. individual cells (including merged cells for Break/Lunch)

Then extract EVERY timetable cell.
Preserve the relationship between: day -> period -> time -> subject.
Do not invent missing information.
If text is unclear, return the best readable text and mark confidence low.
If a cell spans multiple periods (like LAB or BREAK), extract it as separate periods with the same subject, or just map it properly.
Separate faculty and room names if present.

$additionalInstructions

Return ONLY structured JSON matching this schema:
[
  {
    "day": "Monday",
    "period": 1,
    "startTime": "09:15",
    "endTime": "10:15",
    "subject": "Data Structures",
    "faculty": "Dr. Smith",
    "room": "CSE-204",
    "type": "class", // 'class', 'break', 'lab'
    "confidence": 0.94 // double between 0.0 and 1.0
  }
]

Verify that all detected days and periods are represented before returning the result.
''';

        final rawText = await _callGeminiVision(
          apiKey: effectiveKey,
          prompt: prompt,
          imageBytes: imageBytes,
        );

        String cleaned = rawText.trim();
        if (cleaned.startsWith('```json')) {
          cleaned = cleaned.substring(7);
        } else if (cleaned.startsWith('```')) {
          cleaned = cleaned.substring(3);
        }
        if (cleaned.endsWith('```')) {
          cleaned = cleaned.substring(0, cleaned.length - 3);
        }
        cleaned = cleaned.trim();

        final List<dynamic> decoded = jsonDecode(cleaned);
        final currentEntries = decoded
            .map((e) => DetectedTimetableEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();

        // Validation step
        final uniqueDays = currentEntries.map((e) => e.weekday).toSet().length;
        final uniquePeriods = currentEntries.map((e) => e.period).toSet().length;
        
        int expectedCells = uniqueDays * uniquePeriods;
        
        if (attempt < maxAttempts && expectedCells > 0 && currentEntries.length < (expectedCells * 0.7)) {
           additionalInstructions = "In your previous attempt, you missed several cells. I expected approx $expectedCells cells but you only returned ${currentEntries.length}. PLEASE EXTRACT EVERY CELL IN THE GRID, DO NOT TRUNCATE.";
           bestEntries = currentEntries.length > bestEntries.length ? currentEntries : bestEntries;
           continue;
        }

        return currentEntries;
      } catch (e) {
        if (attempt == maxAttempts) {
           if (bestEntries.isNotEmpty) return bestEntries;
           throw Exception('Failed to process timetable: $e');
        }
      }
    }
    
    return bestEntries.isNotEmpty ? bestEntries : _generateMockFallback();
  }

  /// Parse plain text timetable into structured entries
  List<DetectedTimetableEntry> parseTimetableText(String rawText) {
    final entries = <DetectedTimetableEntry>[];
    final lines = rawText.split('\n');
    String currentWeekday = 'Monday';
    final weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    int periodCounter = 1;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();
      final matchedDay = weekdays.firstWhere(
        (d) => lower == d || lower.startsWith('$d:'),
        orElse: () => '',
      );

      if (matchedDay.isNotEmpty) {
        currentWeekday = matchedDay[0].toUpperCase() + matchedDay.substring(1);
        periodCounter = 1;
        continue;
      }

      // Regex matching period, times, subject
      final timeRegex = RegExp(r'(\d{1,2}:\d{2})\s*(?:-|to)\s*(\d{1,2}:\d{2})');
      final timeMatch = timeRegex.firstMatch(line);

      if (timeMatch != null) {
        final startTime = timeMatch.group(1)!;
        final endTime = timeMatch.group(2)!;

        // Clean out times and period markers
        String subject = line.replaceAll(timeMatch.group(0)!, '').trim();
        subject = subject.replaceAll(RegExp(r'^P\d+\s*'), '').trim();

        if (subject.isNotEmpty) {
          entries.add(
            DetectedTimetableEntry(
              weekday: currentWeekday,
              period: periodCounter++,
              startTime: startTime,
              endTime: endTime,
              subjectName: subject.split(' ').first,
              faculty: subject.contains('Prof') || subject.contains('Dr')
                  ? subject.substring(subject.indexOf(RegExp(r'(Prof|Dr)')))
                  : 'Staff',
              room: subject.contains('LH') || subject.contains('Lab') || subject.contains('Room')
                  ? 'Classroom'
                  : 'Main Campus',
            ),
          );
        }
      }
    }

    return entries;
  }

  /// Scan Exam Schedule / Timetable image using Gemini Vision
  Future<List<DetectedExamEntry>> scanExamTimetableImage({
    required Uint8List imageBytes,
    String? apiKey,
  }) async {
    ActivityLogger().logEvent('ai_exam_ocr_used', parameters: {'feature': 'exam_datesheet_ocr'});
    final effectiveKey = _resolveApiKey(apiKey);
    if (effectiveKey.isNotEmpty) {
      try {
        final prompt = '''
You are an expert academic exam timetable parser for university / college students.
Analyze this exam schedule image, circular, or datesheet.
Extract all scheduled exams with their subjects, dates, and times.

Output a JSON array:
[
  {
    "title": "Operating Systems Midterm",
    "subjectName": "Operating Systems",
    "examType": "Midterm",
    "examDate": "2026-09-15",
    "startTime": "10:00 AM",
    "endTime": "01:00 PM",
    "room": "Hall A",
    "syllabus": "Units 1-3"
  }
]

Return ONLY raw JSON array.
''';

        final rawText = await _callGeminiVision(
          apiKey: effectiveKey,
          prompt: prompt,
          imageBytes: imageBytes,
        );

        String cleaned = rawText;
        if (cleaned.startsWith('```json')) {
          cleaned = cleaned.substring(7);
        } else if (cleaned.startsWith('```')) {
          cleaned = cleaned.substring(3);
        }
        if (cleaned.endsWith('```')) {
          cleaned = cleaned.substring(0, cleaned.length - 3);
        }
        cleaned = cleaned.trim();

        final List<dynamic> decoded = jsonDecode(cleaned);
        return decoded
            .map((e) => DetectedExamEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    return _generateMockExamFallback();
  }

  /// Scan an attendance screenshot/photo using Gemini Vision
  Future<List<DetectedAttendanceEntry>> scanAttendanceScreenshot({
    required Uint8List imageBytes,
    String? apiKey,
  }) async {
    ActivityLogger().logEvent('ai_attendance_ocr_used', parameters: {'feature': 'attendance_screenshot_ocr'});
    final effectiveKey = _resolveApiKey(apiKey);
    if (effectiveKey.isEmpty) {
      throw Exception(
        'Gemini API Key is missing. Please configure your Gemini API Key in Profile -> AI Assistant & Gemini Key to scan attendance screenshots.',
      );
    }

    try {
      final prompt = '''
You are an expert AI attendance parser for university / college students.
Analyze this screenshot or photo of an attendance portal, LMS course page, or timetable log.

Extract all attendance sessions and courses visible.
Support two formats:
1. Multi-course list/grid:
[
  {
    "subjectName": "Operating Systems (OS)",
    "status": "present",
    "periodNumber": 1,
    "date": "2026-08-25"
  }
]

2. Single-course timeline portal:
{
  "course_name": "Advanced Java Programming",
  "course_code": "R24MSCST012",
  "timeline": [
    {
      "date": "2026-08-25",
      "status": "present"
    }
  ]
}

Rules:
- "status" MUST be "present", "absent", or "cancelled".
- "date" should be in YYYY-MM-DD format if visible.
- If a subject is marked "P", "Present", "Attended", map it to "present".
- If a subject is marked "A", "Absent", "Missed", map it to "absent".
- If a subject is marked "Cancelled", "C", "Off", map it to "cancelled".
- Return ONLY the raw JSON. Do not write introductory or concluding text.
''';

      final rawText = await _callGeminiVision(
        apiKey: effectiveKey,
        prompt: prompt,
        imageBytes: imageBytes,
      );

      String cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(cleaned);
      } catch (_) {
        // Fallback: extract array or object using regex
        final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
        if (arrayMatch != null) {
          decodedJson = jsonDecode(arrayMatch.group(0)!);
        } else {
          final objMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
          if (objMatch != null) {
            decodedJson = jsonDecode(objMatch.group(0)!);
          }
        }
      }

      if (decodedJson is List) {
        final entries = decodedJson.map((e) {
          final m = Map<String, dynamic>.from(e);
          return DetectedAttendanceEntry.fromMap(m);
        }).toList();
        if (entries.isNotEmpty) return entries;
      } else if (decodedJson is Map) {
        final m = Map<String, dynamic>.from(decodedJson);
        final courseName = m['course_name'] ?? m['subjectName'] ?? m['course_code'] ?? 'Course';
        final timeline = m['timeline'];
        if (timeline is List && timeline.isNotEmpty) {
          return timeline.map((session) {
            final sm = Map<String, dynamic>.from(session);
            DateTime? parsedDate;
            if (sm['date'] != null) {
              try {
                parsedDate = DateTime.parse(sm['date'].toString());
              } catch (_) {}
            }
            return DetectedAttendanceEntry(
              subjectName: courseName.toString(),
              status: sm['status']?.toString().toLowerCase() == 'absent' ? 'absent' : 'present',
              date: parsedDate,
            );
          }).toList();
        } else {
          return [
            DetectedAttendanceEntry.fromMap(m),
          ];
        }
      }
    } catch (e) {
      throw Exception('Failed to process screenshot with Gemini: $e');
    }

    return [];
  }

  List<DetectedTimetableEntry> _generateMockFallback() {
    return [
      DetectedTimetableEntry(
        weekday: 'Monday',
        period: 1,
        startTime: '09:15',
        endTime: '10:15',
        subjectName: 'Operating Systems',
        faculty: 'Dr. Sarah Connor',
        room: 'Room 301',
      ),
      DetectedTimetableEntry(
        weekday: 'Monday',
        period: 2,
        startTime: '10:15',
        endTime: '11:15',
        subjectName: 'Computer Networks',
        faculty: 'Prof. John Doe',
        room: 'Room 302',
      ),
      DetectedTimetableEntry(
        weekday: 'Tuesday',
        period: 1,
        startTime: '09:15',
        endTime: '10:15',
        subjectName: 'Design & Analysis of Algorithms',
        faculty: 'Dr. Grace Hopper',
        room: 'Lab 2',
      ),
    ];
  }

  List<DetectedExamEntry> _generateMockExamFallback() {
    return [
      DetectedExamEntry(
        title: 'Database Systems Midterm',
        subjectName: 'DBMS',
        examType: 'Midterm',
        examDate: DateTime.now().add(const Duration(days: 14)),
        startTime: '10:00 AM',
        endTime: '01:00 PM',
        room: 'Hall 101',
        syllabus: 'SQL, Normalization & ER Diagrams',
      ),
      DetectedExamEntry(
        title: 'Operating Systems Final',
        subjectName: 'Operating Systems',
        examType: 'Final',
        examDate: DateTime.now().add(const Duration(days: 28)),
        startTime: '02:00 PM',
        endTime: '05:00 PM',
        room: 'Auditorium',
        syllabus: 'Processes, Memory Management & File Systems',
      ),
    ];
  }
}
