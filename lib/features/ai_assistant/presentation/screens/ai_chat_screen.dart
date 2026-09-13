import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/core/config/ai_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:trackx/routing/nav_provider.dart';
import 'package:trackx/core/services/activity_logger.dart';
import 'package:trackx/features/ai_assistant/domain/services/ai_document_analyzer_service.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_context_builder.dart';
import 'package:trackx/features/ai_assistant/data/services/gemini_provider.dart';
import 'package:trackx/features/ai_assistant/presentation/screens/ai_assistant_settings_screen.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_response.dart';
import 'package:trackx/features/ai_assistant/providers/ai_providers.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/attendance/providers/stats_provider.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/planner/domain/models/productivity_models.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';
import 'package:trackx/features/timetable/domain/models/timetable_entry_model.dart';
import 'package:trackx/features/calendar/providers/calendar_provider.dart';
import 'package:trackx/theme/app_theme.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _docAnalyzer = AiDocumentAnalyzerService();
  final List<Map<String, dynamic>> _messages = [];
  bool _hasInitializedGreeting = false;
  bool _isBriefExpanded = false;

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
    return 555;
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
        await _handleDocumentUpload(
          bytes,
          source == ImageSource.camera
              ? 'Camera Photo.jpg'
              : 'Gallery Image.jpg',
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
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'txt'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _handleDocumentUpload(file.bytes!, file.name);
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

  Future<void> _handleDocumentUpload(Uint8List bytes, String fileName) async {
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add({
        'isBot': false,
        'text': '📄 Uploaded: $fileName',
        'isDocument': true,
      });
      _messages.add({
        'isBot': true,
        'text': '🤖 Analyzing "$fileName" with Multimodal Vision AI...',
        'isLoading': true,
      });
    });

    final settings = ref.read(aiSettingsProvider);
    final result = await _docAnalyzer.analyzeDocument(
      bytes: bytes,
      fileName: fileName,
      apiKey: settings.customApiKey,
    );

    if (!mounted) return;

    setState(() {
      _messages.removeWhere((m) => m['isLoading'] == true);
      _messages.add({
        'isBot': true,
        'text': '📄 **${result.title}**\n\n${result.summary}',
        'actions': result.actionLabels,
        'analysisResult': result,
      });
    });
  }

  void _showAttachmentOptions() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = context.cardColor;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final iconBg = isDark ? const Color(0xFF1B243B) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Document or Photo to AI',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AI will automatically recognize your timetable, exam date-sheet, or assignment.',
                style: TextStyle(color: subtextColor, fontSize: 12),
              ),
              const SizedBox(height: 18),

              // Camera
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF7BD0FF),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Capture printed notice or timetable',
                  style: TextStyle(color: subtextColor, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),

              // Gallery
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFFC0C1FF),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Choose Image from Gallery',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Select a schedule screenshot or photo',
                  style: TextStyle(color: subtextColor, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),

              // PDF
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFFF8B94),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Upload PDF / Document',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Select any academic timetable or date-sheet PDF',
                  style: TextStyle(color: subtextColor, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
    String act, [
    AiDocumentAnalysisResult? analysisResult,
  ]) async {
    HapticFeedback.mediumImpact();
    final activeSem = ref.read(activeSemesterProvider);
    final subRepo = ref.read(subjectRepositoryProvider.notifier);
    final ttRepo = ref.read(timetableRepositoryProvider.notifier);
    final examsNotifier = ref.read(examsProvider.notifier);
    final tasksNotifier = ref.read(tasksProvider.notifier);

    if (act.contains('Timetable & Attendance') || act.contains('Timetable')) {
      if (analysisResult != null &&
          analysisResult.detectedTimetable.isNotEmpty) {
        final entries = analysisResult.detectedTimetable;
        for (final e in entries) {
          if (activeSem != null) {
            await subRepo.addSubject(
              activeSem.id,
              e.subjectName,
              e.faculty.isNotEmpty ? e.faculty : 'Faculty',
              AppTheme.accentPurple.toARGB32(),
              activeSem.attendanceTarget,
            );
            final subs = ref.read(subjectRepositoryProvider);
            final subId = subs
                .firstWhere(
                  (s) =>
                      s.name.toLowerCase() ==
                      e.subjectName.trim().toLowerCase(),
                  orElse: () => subs.first,
                )
                .id;
            await ttRepo.addEntry(
              TimetableEntry(
                id: 'tt-${DateTime.now().millisecondsSinceEpoch}-${e.period}',
                userId: 'user',
                semesterId: activeSem.id,
                subjectId: subId,
                dayOfWeek: _weekdayToInt(e.weekday),
                periodNumber: e.period,
                startTime: _timeToMinutes(e.startTime),
                endTime: _timeToMinutes(e.endTime),
                room: e.room,
                isEnabled: true,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
          }
        }
        setState(() {
          _messages.add({
            'isBot': true,
            'text':
                '✅ Applied ${entries.length} scheduled periods and subjects to your Timetable & Attendance page!',
            'actions': ['View Attendance', 'View Timetable'],
          });
        });
      }
    } else if (act.contains('Exams in Planner') || act.contains('Exam')) {
      if (analysisResult != null && analysisResult.detectedExams.isNotEmpty) {
        int count = 0;
        for (final ex in analysisResult.detectedExams) {
          examsNotifier.addExam(
            Exam(
              id: 'exam-${DateTime.now().millisecondsSinceEpoch}-$count',
              userId: 'user',
              semesterId: activeSem?.id ?? 'sem-1',
              subjectId: 'sub-1',
              title: ex.title,
              examType: ex.examType,
              examDate: ex.examDate,
              startTime: ex.startTime,
              endTime: ex.endTime.isNotEmpty ? ex.endTime : null,
              syllabus: ex.syllabus,
              preparationProgress: 0.0,
              notes: ex.room.isNotEmpty ? 'Room: ${ex.room}' : null,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          count++;
        }
        setState(() {
          _messages.add({
            'isBot': true,
            'text':
                '✅ Successfully scheduled $count examinations with revision countdowns into your Planner!',
            'actions': ['View Planner'],
          });
        });
      }
    } else if (act.contains('Holidays in Calendar') || act.contains('Mark Holidays')) {
      if (analysisResult != null && analysisResult.detectedHolidays.isNotEmpty) {
        final count = await ref
            .read(calendarRepositoryProvider.notifier)
            .batchAddCustomHolidays(analysisResult.detectedHolidays);
        setState(() {
          _messages.add({
            'isBot': true,
            'text':
                '✅ Successfully marked $count college holidays on your Calendar and Attendance Schedule!',
            'actions': ['View Attendance', 'View Planner'],
          });
        });
      }
    } else if (act.contains('Tasks to Planner') || act.contains('Tasks')) {
      if (analysisResult != null && analysisResult.detectedTasks.isNotEmpty) {
        for (final t in analysisResult.detectedTasks) {
          tasksNotifier.addTask(t);
        }
        setState(() {
          _messages.add({
            'isBot': true,
            'text':
                '✅ Added ${analysisResult.detectedTasks.length} assignment tasks to your Planner!',
            'actions': ['View Planner'],
          });
        });
      }
    } else if (act == 'Attendance Summary' ||
        act == 'Plan Study Week' ||
        act == 'Schedule Study Block' ||
        act == 'Setup Profile' ||
        act == 'Add Subject' ||
        act.contains('Study Block') ||
        act.contains('Summary')) {
      _sendMessage(act);
    } else if (act.contains('Attendance')) {
      ref.read(navIndexProvider.notifier).state = 1;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Switched to Attendance.')));
    } else if (act.contains('Planner')) {
      ref.read(navIndexProvider.notifier).state = 2;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Switched to Planner.')));
    } else {
      _sendMessage(act);
    }
  }

  Future<void> _handleSuggestedAction(AiSuggestedAction act) async {
    HapticFeedback.mediumImpact();
    final tasksNotifier = ref.read(tasksProvider.notifier);
    final activeSem = ref.read(activeSemesterProvider);

    if (act.type == 'CreatePlannerTask' ||
        act.type == 'CreateTask' ||
        act.type == 'CreateStudySession') {
      final title = act.parameters['title'] as String? ?? act.title;
      final category = act.parameters['category'] as String? ?? 'Study';
      final duration = act.parameters['durationMinutes'] as int? ?? 45;

      DateTime dueDate = DateTime.now().add(const Duration(days: 1));
      if (act.parameters['dueDate'] != null) {
        dueDate =
            DateTime.tryParse(act.parameters['dueDate'].toString()) ?? dueDate;
      }

      tasksNotifier.addTask(
        Task(
          id: 'task-ai-${DateTime.now().millisecondsSinceEpoch}',
          userId: 'user',
          semesterId: activeSem?.id ?? 'sem-1',
          title: title,
          description: 'AI Suggested: $duration min focus session',
          category: category,
          priority: 'High',
          dueDate: dueDate,
          isCompleted: false,
          recurrenceRule: 'None',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      setState(() {
        _messages.add({
          'isBot': true,
          'text': '✅ Scheduled task "$title" into your Planner!',
          'actions': ['View Planner'],
        });
      });
    } else if (act.type == 'DeclareHoliday' || act.type == 'MarkHoliday') {
      final title = act.parameters['title'] as String? ?? act.title;
      final dateStr = act.parameters['date'] as String? ?? act.parameters['dueDate']?.toString();
      final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
      await ref.read(calendarRepositoryProvider.notifier).addCustomHoliday(date: date, title: title);
      setState(() {
        _messages.add({
          'isBot': true,
          'text': '✅ Marked "$title" as a holiday on ${DateFormat('MMM dd, yyyy').format(date)} across your Calendar & Attendance schedule!',
          'actions': ['View Attendance', 'View Calendar'],
        });
      });
    } else if (act.type == 'OpenAiSettings' ||
        act.title.toLowerCase().contains('settings')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AiAssistantSettingsScreen(),
        ),
      );
    } else if (act.type == 'OpenAttendance' ||
        act.title.toLowerCase().contains('attendance')) {
      ref.read(navIndexProvider.notifier).state = 1;
    } else if (act.type == 'OpenPlanner' ||
        act.title.toLowerCase().contains('planner')) {
      ref.read(navIndexProvider.notifier).state = 2;
    } else if (act.type == 'OpenTimetable' ||
        act.title.toLowerCase().contains('timetable')) {
      ref.read(navIndexProvider.notifier).state = 0;
    } else {
      _handleAction(act.title);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedGreeting) {
      _hasInitializedGreeting = true;
      _initDynamicGreeting();
    }
  }

  void _initDynamicGreeting() {
    final stats = ref.read(statsProvider);
    final exams = ref.read(examsProvider);
    final profile = ref.read(authRepositoryProvider).userProfile;

    String greeting;
    List<String>? actions;

    if (profile == null || !profile.onboardingCompleted) {
      greeting =
          'Hello! Complete your profile to get personalized recommendations.';
      actions = ['Setup Profile'];
    } else if (stats.allSubjectStats.isEmpty) {
      greeting =
          'Welcome to TrackX AI! Ask me any general knowledge question, study advice, coding problem, or add your timetable to get schedule insights.';
      actions = ['Add Subject', 'Import Timetable'];
    } else if (exams.isNotEmpty) {
      final nextExam = exams.first;
      final daysLeft = nextExam.examDate.difference(DateTime.now()).inDays;
      final timeStr = daysLeft <= 0
          ? 'today'
          : (daysLeft == 1 ? 'tomorrow' : 'in $daysLeft days');
      greeting =
          'Good day, ${profile.name}! Your ${nextExam.title} exam is $timeStr. How can I assist you with your preparation or questions today?';
      actions = ['Schedule Study Block', 'View Exam Details'];
    } else {
      greeting =
          'Hello ${profile.name}! How can I help you today? Ask me any question, study guidance, or academic schedule query.';
      actions = ['Attendance Summary', 'Plan Study Week'];
    }

    setState(() {
      _messages.add({'isBot': true, 'text': greeting, 'actions': actions});
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customPrompt]) async {
    final text = (customPrompt ?? _textController.text).trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _textController.clear();

    setState(() {
      _messages.add({'isBot': false, 'text': text});
      _messages.add({
        'isBot': true,
        'text': 'Gemini is thinking...',
        'isLoading': true,
      });
    });
    _scrollToBottom();

    try {
      final settings = ref.read(aiSettingsProvider);
      final usageNotifier = ref.read(aiUsageProvider.notifier);
      final usageSummary = ref.read(aiUsageProvider);

      if (!settings.enableAi) {
        setState(() {
          _messages.removeWhere((m) => m['isLoading'] == true);
          _messages.add({
            'isBot': true,
            'text':
                '⚠️ AI Assistant features are currently disabled. Please enable them in Privacy settings.',
          });
        });
        _scrollToBottom();
        return;
      }

      if (usageSummary.requestsToday >= usageSummary.maxDailyRequests) {
        setState(() {
          _messages.removeWhere((m) => m['isLoading'] == true);
          _messages.add({
            'isBot': true,
            'text':
                '⚠️ You have reached your daily limit of ${usageSummary.maxDailyRequests} requests. Please retry tomorrow.',
          });
        });
        _scrollToBottom();
        return;
      }

      // Live Online Gemini Provider
      final provider = GeminiAiProvider(overrideApiKey: settings.customApiKey);

      final authState = ref.read(authRepositoryProvider);
      final profile = authState.userProfile;
      if (profile == null) {
        setState(() {
          _messages.removeWhere((m) => m['isLoading'] == true);
          _messages.add({
            'isBot': true,
            'text': '⚠️ User profile is not loaded.',
          });
        });
        _scrollToBottom();
        return;
      }

      String? subjectFilterId;
      final subjects = ref.read(subjectRepositoryProvider);
      for (final s in subjects) {
        if (text.toLowerCase().contains(s.name.toLowerCase()) ||
            (s.code != null &&
                text.toLowerCase().contains(s.code!.toLowerCase()))) {
          subjectFilterId = s.id;
          break;
        }
      }

      final aiContext = AiContextBuilder.build(
        profile: profile,
        semesters: ref.read(semesterRepositoryProvider),
        subjects: subjects,
        attendance: ref.read(attendanceRepositoryProvider),
        tasks: ref.read(tasksProvider),
        assignments: ref.read(assignmentsProvider),
        exams: ref.read(examsProvider),
        timetable: ref.read(timetableRepositoryProvider),
        consentFlags: settings.consentFlags,
        subjectFilterId: subjectFilterId,
      );

      AiFeatureType featureType = AiFeatureType.generalChat;
      final lower = text.toLowerCase();
      if (lower.contains('miss') ||
          lower.contains('attendance') ||
          lower.contains('bunk')) {
        featureType = AiFeatureType.attendanceExplanation;
      } else if (lower.contains('study') ||
          lower.contains('schedule') ||
          lower.contains('plan')) {
        featureType = AiFeatureType.studyPlanning;
      } else if (lower.contains('exam') || lower.contains('countdown')) {
        featureType = AiFeatureType.examPreparation;
      } else if (lower.contains('assignment') || lower.contains('breakdown')) {
        featureType = AiFeatureType.assignmentBreakdown;
      }

      final request = AiRequest(
        id: 'req-${DateTime.now().millisecondsSinceEpoch}',
        userId: profile.id,
        featureType: featureType,
        userPrompt: text,
        context: aiContext.toMap(),
        conversationId: 'default',
        modelId: AiConfig.geminiModel,
        createdAt: DateTime.now(),
      );

      final response = await provider.generate(request);
      await usageNotifier.incrementRequests();

      ref.read(activityLoggerProvider).logEvent('ai_query_sent', parameters: {
        'prompt_length': text.length,
        'feature': featureType.name,
      });

      if (!mounted) return;

      final actionLabels =
          response.suggestedActions.map((a) => a.title).toList();

      setState(() {
        _messages.removeWhere((m) => m['isLoading'] == true);
        _messages.add({
          'isBot': true,
          'text': response.text,
          'actions': actionLabels.isNotEmpty ? actionLabels : null,
          'suggestedActions': response.suggestedActions,
          'sources': response.sources,
          'confidence': response.confidence,
          'limitations': response.limitations,
        });
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['isLoading'] == true);
        _messages.add({
          'isBot': true,
          'text': '⚠️ An error occurred while contacting Gemini: $e',
        });
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final exams = ref.watch(examsProvider);
    final subjects = ref.watch(subjectRepositoryProvider);
    final settings = ref.watch(aiSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;
    final mutedTextColor = context.mutedTextColor;
    final cardBg = isDark ? const Color(0xFF131A2B) : const Color(0xFFFFFFFF);
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);
    final botBubbleBg = isDark ? const Color(0xFF1B243B) : const Color(0xFFF1F5F9);
    final userBubbleBg = isDark ? const Color(0xFF252A4A) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            onTap: () => ref.read(navIndexProvider.notifier).state = 4,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: isDark ? const Color(0xFF1B243B) : const Color(0xFFE2E8F0),
              child: Icon(
                Icons.person_rounded,
                color: subtextColor,
                size: 20,
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              'TrackX AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 18,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Gemini Flash • Live Online',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: textColor,
              size: 22,
            ),
            tooltip: 'New Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _initDynamicGreeting();
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: textColor,
              size: 22,
            ),
            tooltip: 'AI Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AiAssistantSettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              children: [
                if (settings.customApiKey.isEmpty)
                  _buildApiKeyBanner(textColor, subtextColor, isDark),

                if (_messages.length <= 1) ...[
                  _buildGeminiWelcomeHero(textColor, subtextColor, isDark),
                  const SizedBox(height: 14),
                  _buildQuickPromptChips(isDark, textColor, subtextColor),
                  const SizedBox(height: 16),
                  _buildCollapsibleAcademicBrief(
                    stats: stats,
                    exams: exams,
                    subjects: subjects,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],

                // Chat Messages
                ..._messages.map((msg) {
                  final isBot = msg['isBot'] as bool;
                  final text = msg['text'] as String;
                  final isLoading = msg['isLoading'] == true;
                  final actions = msg['actions'] as List<String>?;
                  final suggestedActions =
                      msg['suggestedActions'] as List<AiSuggestedAction>?;
                  final sources = msg['sources'] as List<AiSourceReference>?;
                  final limitations = msg['limitations'] as List<String>?;

                  if (isBot) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: botBubbleBg,
                            ),
                            child: Icon(
                              isLoading
                                  ? Icons.auto_awesome_rounded
                                  : Icons.smart_toy_outlined,
                              color: const Color(0xFFC0C1FF),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: botBubbleBg,
                                borderRadius: BorderRadius.circular(18),
                                border: isLoading
                                    ? Border.all(
                                        color: const Color(0xFF5B5FEF)
                                            .withValues(alpha: 0.4),
                                      )
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isLoading)
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFC0C1FF),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            text,
                                            style: TextStyle(
                                              color: subtextColor,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    _buildFormattedText(
                                      text,
                                      textColor,
                                      subtextColor,
                                      isDark,
                                    ),

                                  // Sources References
                                  if (sources != null &&
                                      sources.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: sources.map((src) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                                            ),
                                          ),
                                          child: Text(
                                            '📚 ${src.title}: ${src.detail}',
                                            style: TextStyle(
                                              color: subtextColor,
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],

                                  // Limitations / Diagnostics
                                  if (limitations != null &&
                                      limitations.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ...limitations.map(
                                      (lim) => Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          'ℹ️ $lim',
                                          style: TextStyle(
                                            color: mutedTextColor,
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // 1-Tap Suggested Actions from Gemini
                                  if (suggestedActions != null &&
                                      suggestedActions.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: suggestedActions.map((sug) {
                                        return GestureDetector(
                                          onTap: () =>
                                              _handleSuggestedAction(sug),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5B5FEF)
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF5B5FEF)
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.auto_awesome_rounded,
                                                  color: Color(0xFFC0C1FF),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  sug.title,
                                                  style: const TextStyle(
                                                    color: Color(0xFFC0C1FF),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ] else if (actions != null) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: actions.map((act) {
                                        IconData chipIcon =
                                            Icons.arrow_forward_rounded;
                                        Color chipColor =
                                            const Color(0xFF5B5FEF);
                                        if (act.contains('Timetable')) {
                                          chipIcon = Icons.table_chart_rounded;
                                          chipColor = const Color(0xFF10B981);
                                        } else if (act.contains('Exam')) {
                                          chipIcon = Icons.event_note_rounded;
                                          chipColor = const Color(0xFFFF8B94);
                                        } else if (act.contains('Task')) {
                                          chipIcon = Icons.task_alt_rounded;
                                          chipColor = const Color(0xFF7BD0FF);
                                        } else if (act.contains('Attendance')) {
                                          chipIcon = Icons
                                              .assignment_turned_in_rounded;
                                          chipColor = const Color(0xFFC0C1FF);
                                        }

                                        return GestureDetector(
                                          onTap: () => _handleAction(
                                            act,
                                            msg['analysisResult']
                                                as AiDocumentAnalysisResult?,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: chipColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: chipColor.withValues(
                                                  alpha: 0.4,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  chipIcon,
                                                  color: chipColor,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  act,
                                                  style: TextStyle(
                                                    color: chipColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
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
                        ],
                      ),
                    );
                  } else {
                    final isDoc = msg['isDocument'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDoc
                                    ? botBubbleBg
                                    : userBubbleBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDoc
                                      ? const Color(
                                          0xFF7BD0FF,
                                        ).withValues(alpha: 0.4)
                                      : const Color(
                                          0xFF5B5FEF,
                                        ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: botBubbleBg,
                            child: Icon(
                              Icons.person_rounded,
                              color: subtextColor,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }),
              ],
            ),
          ),

          // Bottom Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
            child: GlassContainer(
              tier: GlassTier.modal,
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showAttachmentOptions,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131A2B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.attach_file_rounded,
                        color: Color(0xFF7BD0FF),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassContainer(
                      tier: GlassTier.subtle,
                      borderRadius: 16,
                      showLightRim: false,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask AI or upload PDF...',
                          hintStyle: TextStyle(
                            color: mutedTextColor,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B5FEF),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF5B5FEF,
                            ).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyBanner(Color textColor, Color subtextColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF5B5FEF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5B5FEF).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.key_rounded,
              color: Color(0xFFC0C1FF),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Google Gemini API Key',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add your free Gemini API key to chat and ask any questions.',
                  style: TextStyle(color: subtextColor, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AiAssistantSettingsScreen(),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5FEF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add Key',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiWelcomeHero(Color textColor, Color subtextColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF5B5FEF), Color(0xFF7BD0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B5FEF).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'How can I help you today?',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask any general knowledge, code, study guidance, or timetable question.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptChips(bool isDark, Color textColor, Color subtextColor) {
    final prompts = [
      {'icon': '🎓', 'text': 'Can I bunk tomorrow?'},
      {'icon': '📅', 'text': 'What classes do I have today?'},
      {'icon': '📚', 'text': 'Create a study schedule for my exams'},
      {'icon': '💡', 'text': 'Explain binary search algorithm with code'},
      {'icon': '✍️', 'text': 'Help me write an essay on artificial intelligence'},
      {'icon': '⚡', 'text': 'How do I calculate required attendance recovery?'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prompts.map((p) {
        return InkWell(
          onTap: () => _sendMessage(p['text']!),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B243B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p['icon']!, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Text(
                  p['text']!,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCollapsibleAcademicBrief({
    required dynamic stats,
    required dynamic exams,
    required dynamic subjects,
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isBriefExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isBriefExpanded = expanded);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF5B5FEF).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Color(0xFFC0C1FF),
              size: 18,
            ),
          ),
          title: Text(
            'Academic Snapshot',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
          subtitle: Text(
            stats.allSubjectStats.isEmpty
                ? 'No subjects enrolled yet'
                : '${stats.overallPercentage.toStringAsFixed(0)}% Overall • ${exams.length} Upcoming Exams',
            style: TextStyle(color: subtextColor, fontSize: 11),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    stats.allSubjectStats.isEmpty
                        ? 'Add your subjects and attendance to get personalized insights.'
                        : 'Attendance is ${stats.overallPercentage >= stats.globalTarget ? 'safely above' : 'below'} your ${stats.globalTarget.toStringAsFixed(0)}% target across ${subjects.length} enrolled subjects.',
                    style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(navIndexProvider.notifier).state = 1,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                            side: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('View Attendance', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(navIndexProvider.notifier).state = 2,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                            side: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('View Planner', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String content, Color textColor, Color subtextColor, bool isDark) {
    final lines = content.split('\n');
    final List<Widget> children = [];
    bool inCodeBlock = false;
    final List<String> codeLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          children.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black45 : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                codeLines.join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFFC0C1FF),
                ),
              ),
            ),
          );
          codeLines.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeLines.add(line);
        continue;
      }

      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // Headers (### Header)
      if (trimmed.startsWith('### ') || trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final title = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        continue;
      }

      // Bullet points
      if (trimmed.startsWith('• ') || trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
        final bulletText = trimmed.substring(2).trim();
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    color: Color(0xFFC0C1FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: _buildRichInlineText(bulletText, textColor),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular paragraph line
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildRichInlineText(line, textColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildRichInlineText(String text, Color defaultColor) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(color: defaultColor, fontSize: 13.5, height: 1.4),
        ));
      }
      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: TextStyle(
            color: defaultColor,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            height: 1.4,
          ),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: TextStyle(
            color: defaultColor,
            fontStyle: FontStyle.italic,
            fontSize: 13.5,
            height: 1.4,
          ),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFC0C1FF),
            backgroundColor: Colors.black26,
            fontSize: 12.5,
          ),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(color: defaultColor, fontSize: 13.5, height: 1.4),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }
}

