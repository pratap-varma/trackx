import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:trackx/routing/nav_provider.dart';
import 'package:trackx/core/services/activity_logger.dart';
import 'package:trackx/features/ai_assistant/domain/services/ai_document_analyzer_service.dart';
import 'package:trackx/features/ai_assistant/data/services/ai_context_builder.dart';
import 'package:trackx/features/ai_assistant/data/services/gemini_provider.dart';
import 'package:trackx/features/ai_assistant/data/services/offline_fallback_provider.dart';
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
import 'package:trackx/theme/app_theme.dart';
import 'package:trackx/shared/widgets/glass_container.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _textController = TextEditingController();
  final _docAnalyzer = AiDocumentAnalyzerService();
  final List<Map<String, dynamic>> _messages = [];
  bool _hasInitializedGreeting = false;

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
    final sheetBg = isDark ? const Color(0xFF0E1628) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
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
          'Welcome to TrackX AI! No attendance data yet. Add your subjects and attendance to get personalized insights.';
      actions = ['Add Subject', 'Import Timetable'];
    } else if (exams.isNotEmpty) {
      final nextExam = exams.first;
      final daysLeft = nextExam.examDate.difference(DateTime.now()).inDays;
      final timeStr = daysLeft <= 0
          ? 'today'
          : (daysLeft == 1 ? 'tomorrow' : 'in $daysLeft days');
      greeting =
          'Good day, ${profile.name}! Your ${nextExam.title} exam is $timeStr. Would you like me to schedule a revision session?';
      actions = ['Schedule Study Block', 'View Exam Details'];
    } else {
      greeting =
          'Hello ${profile.name}! Your overall attendance is at ${stats.overallPercentage.toStringAsFixed(0)}%. How can I help optimize your schedule today?';
      actions = ['Attendance Summary', 'Plan Study Week'];
    }

    setState(() {
      _messages.add({'isBot': true, 'text': greeting, 'actions': actions});
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
        'text': '🤖 Gemini is analyzing your academic data...',
        'isLoading': true,
      });
    });

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
        return;
      }

      final bool useOffline =
          settings.provider == 'Offline only' || settings.provider == 'Offline';
      final provider = useOffline
          ? OfflineFallbackProvider()
          : GeminiAiProvider(overrideApiKey: settings.customApiKey);

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
        modelId: useOffline ? 'offline' : 'gemini-1.5-flash',
        createdAt: DateTime.now(),
      );

      final response = await provider.generate(request);

      if (useOffline) {
        await usageNotifier.incrementOfflineFallback();
      } else {
        await usageNotifier.incrementRequests();
      }

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['isLoading'] == true);
        _messages.add({
          'isBot': true,
          'text': '⚠️ An error occurred while contacting Gemini: $e',
        });
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final exams = ref.watch(examsProvider);
    final subjects = ref.watch(subjectRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFDEE2F4) : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final mutedTextColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
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
        title: Text(
          'TrackX AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: textColor,
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new AI alerts right now.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              children: [
                // 1. Morning Brief Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF5B5FEF).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFC0C1FF),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'MORNING BRIEF',
                                style: TextStyle(
                                  color: Color(0xFFC0C1FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFC0C1FF),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        stats.allSubjectStats.isEmpty
                            ? 'Welcome to TrackX! Complete your profile and add your subjects to get personalized academic insights.'
                            : 'Overall attendance is ${stats.overallPercentage.toStringAsFixed(0)}% across ${subjects.length} enrolled subjects.',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            stats.allSubjectStats.isEmpty
                                ? Icons.info_outline_rounded
                                : (stats.overallPercentage >= stats.globalTarget
                                      ? Icons.trending_up_rounded
                                      : Icons.warning_amber_rounded),
                            color: stats.allSubjectStats.isEmpty
                                ? subtextColor
                                : (stats.overallPercentage >= stats.globalTarget
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFFF8B94)),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              stats.allSubjectStats.isEmpty
                                  ? 'No attendance data yet. Add your subjects and attendance to get personalized insights.'
                                  : (stats.overallPercentage >=
                                            stats.globalTarget
                                        ? 'Attendance is above your ${stats.globalTarget.toStringAsFixed(0)}% target'
                                        : 'Attendance is below your ${stats.globalTarget.toStringAsFixed(0)}% target'),
                              style: TextStyle(
                                color: stats.allSubjectStats.isEmpty
                                    ? subtextColor
                                    : (stats.overallPercentage >=
                                              stats.globalTarget
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFFF8B94)),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Exam Prep Card
                if (exams.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1B243B) : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.school_outlined,
                                    color: Color(0xFFC0C1FF),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Exam: ${exams.first.title}',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Date: ${DateFormat('MMM dd').format(exams.first.examDate)} • Progress: ${exams.first.preparationProgress.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF5B5FEF,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${exams.first.preparationProgress.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Color(0xFFC0C1FF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Suggested: Review core study notes for ${exams.first.title}.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(navIndexProvider.notifier).state =
                                2; // Jump to Planner
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B5FEF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Schedule Study Block',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 3. Attendance Monitor Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: stats.allSubjectStats.isEmpty
                          ? cardBorder
                          : const Color(0xFFFF8B94).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: stats.allSubjectStats.isEmpty
                                  ? const Color(0xFF7BD0FF)
                                  : const Color(0xFFFF8B94),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ATTENDANCE MONITOR',
                            style: TextStyle(
                              color: stats.allSubjectStats.isEmpty
                                  ? const Color(0xFF7BD0FF)
                                  : const Color(0xFFFF8B94),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stats.allSubjectStats.isEmpty
                            ? 'No attendance data yet. Add your subjects and attendance to get personalized insights.'
                            : (stats.overallPercentage >= stats.globalTarget
                                  ? 'Attendance is safely above ${stats.globalTarget.toStringAsFixed(0)}% across enrolled subjects.'
                                  : 'One or more subjects require attendance to maintain your ${stats.globalTarget.toStringAsFixed(0)}% target.'),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(navIndexProvider.notifier).state =
                              1; // Jump to Attendance Log
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'View Attendance Log',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
                                    Text(
                                      text,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
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
}
