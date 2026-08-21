class Task {
  final String id;
  final String userId;
  final String semesterId;
  final String title;
  final String? description;
  final String category; // Assignment, Exam, Study, Project, Personal, Other
  final String? subjectId;
  final String priority; // Low, Medium, High, Urgent
  final DateTime dueDate;
  final String? dueTime;
  final bool isCompleted;
  final int? reminderTime; // epoch ms
  final String recurrenceRule; // Daily, Weekly, Monthly, Custom, None
  final int createdAt;
  final int updatedAt;
  final int? completedAt;

  Task({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.title,
    this.description,
    required this.category,
    this.subjectId,
    required this.priority,
    required this.dueDate,
    this.dueTime,
    required this.isCompleted,
    this.reminderTime,
    required this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  Task copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? title,
    String? description,
    String? category,
    String? subjectId,
    String? priority,
    DateTime? dueDate,
    String? dueTime,
    bool? isCompleted,
    int? reminderTime,
    String? recurrenceRule,
    int? createdAt,
    int? updatedAt,
    int? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subjectId: subjectId ?? this.subjectId,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderTime: reminderTime ?? this.reminderTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'title': title,
      'description': description,
      'category': category,
      'subjectId': subjectId,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'dueTime': dueTime,
      'isCompleted': isCompleted,
      'reminderTime': reminderTime,
      'recurrenceRule': recurrenceRule,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'] ?? 'Other',
      subjectId: map['subjectId'],
      priority: map['priority'] ?? 'Medium',
      dueDate: DateTime.parse(
        map['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      dueTime: map['dueTime'],
      isCompleted: map['isCompleted'] ?? false,
      reminderTime: map['reminderTime'],
      recurrenceRule: map['recurrenceRule'] ?? 'None',
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
      completedAt: map['completedAt'],
    );
  }
}

class Assignment {
  final String id;
  final String userId;
  final String semesterId;
  final String subjectId;
  final String title;
  final String? description;
  final DateTime assignedDate;
  final DateTime dueDate;
  final String? dueTime;
  final String priority;
  final String status; // Not started, In progress, Completed, Overdue
  final List<String> attachmentPaths;
  final String? notes;
  final int? reminderTime;
  final int createdAt;
  final int updatedAt;
  final int? completedAt;

  Assignment({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.subjectId,
    required this.title,
    this.description,
    required this.assignedDate,
    required this.dueDate,
    this.dueTime,
    required this.priority,
    required this.status,
    required this.attachmentPaths,
    this.notes,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  Assignment copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? subjectId,
    String? title,
    String? description,
    DateTime? assignedDate,
    DateTime? dueDate,
    String? dueTime,
    String? priority,
    String? status,
    List<String>? attachmentPaths,
    String? notes,
    int? reminderTime,
    int? createdAt,
    int? updatedAt,
    int? completedAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      notes: notes ?? this.notes,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'assignedDate': assignedDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'dueTime': dueTime,
      'priority': priority,
      'status': status,
      'attachmentPaths': attachmentPaths,
      'notes': notes,
      'reminderTime': reminderTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      assignedDate: DateTime.parse(
        map['assignedDate'] ?? DateTime.now().toIso8601String(),
      ),
      dueDate: DateTime.parse(
        map['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      dueTime: map['dueTime'],
      priority: map['priority'] ?? 'Medium',
      status: map['status'] ?? 'Not started',
      attachmentPaths: List<String>.from(map['attachmentPaths'] ?? []),
      notes: map['notes'],
      reminderTime: map['reminderTime'],
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
      completedAt: map['completedAt'],
    );
  }
}

class Exam {
  final String id;
  final String userId;
  final String semesterId;
  final String subjectId;
  final String title;
  final String
  examType; // Quiz, Midterm, Internal, Lab, Practical, Final, Other
  final DateTime examDate;
  final String startTime;
  final String? endTime;
  final String syllabus;
  final double preparationProgress; // 0.0 to 100.0
  final String? notes;
  final int? reminderTime;
  final int createdAt;
  final int updatedAt;

  // Stage 16 exam prep fields
  final List<String> syllabusTopics;
  final DateTime? preparationStartDate;
  final DateTime? revisionDeadline;
  final String priority; // 'Low', 'Medium', 'High', 'Urgent'
  final String confidence; // 'Low', 'Developing', 'Confident', 'Strong'
  final double plannedStudyHours;
  final double completedStudyHours;
  final int practiceTestCount;

  Exam({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.subjectId,
    required this.title,
    required this.examType,
    required this.examDate,
    required this.startTime,
    this.endTime,
    required this.syllabus,
    required this.preparationProgress,
    this.notes,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
    List<String>? syllabusTopics,
    this.preparationStartDate,
    this.revisionDeadline,
    String? priority,
    String? confidence,
    double? plannedStudyHours,
    double? completedStudyHours,
    int? practiceTestCount,
  }) : syllabusTopics = syllabusTopics ?? [],
       priority = priority ?? 'Medium',
       confidence = confidence ?? 'Developing',
       plannedStudyHours = plannedStudyHours ?? 0.0,
       completedStudyHours = completedStudyHours ?? 0.0,
       practiceTestCount = practiceTestCount ?? 0;

  Exam copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? subjectId,
    String? title,
    String? examType,
    DateTime? examDate,
    String? startTime,
    String? endTime,
    String? syllabus,
    double? preparationProgress,
    String? notes,
    int? reminderTime,
    int? createdAt,
    int? updatedAt,
    List<String>? syllabusTopics,
    DateTime? preparationStartDate,
    DateTime? revisionDeadline,
    String? priority,
    String? confidence,
    double? plannedStudyHours,
    double? completedStudyHours,
    int? practiceTestCount,
  }) {
    return Exam(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      examType: examType ?? this.examType,
      examDate: examDate ?? this.examDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      syllabus: syllabus ?? this.syllabus,
      preparationProgress: preparationProgress ?? this.preparationProgress,
      notes: notes ?? this.notes,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syllabusTopics: syllabusTopics ?? this.syllabusTopics,
      preparationStartDate: preparationStartDate ?? this.preparationStartDate,
      revisionDeadline: revisionDeadline ?? this.revisionDeadline,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      plannedStudyHours: plannedStudyHours ?? this.plannedStudyHours,
      completedStudyHours: completedStudyHours ?? this.completedStudyHours,
      practiceTestCount: practiceTestCount ?? this.practiceTestCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'title': title,
      'examType': examType,
      'examDate': examDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'syllabus': syllabus,
      'preparationProgress': preparationProgress,
      'notes': notes,
      'reminderTime': reminderTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'syllabusTopics': syllabusTopics,
      'preparationStartDate': preparationStartDate?.toIso8601String(),
      'revisionDeadline': revisionDeadline?.toIso8601String(),
      'priority': priority,
      'confidence': confidence,
      'plannedStudyHours': plannedStudyHours,
      'completedStudyHours': completedStudyHours,
      'practiceTestCount': practiceTestCount,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      title: map['title'] ?? '',
      examType: map['examType'] ?? 'Other',
      examDate: DateTime.parse(
        map['examDate'] ?? DateTime.now().toIso8601String(),
      ),
      startTime: map['startTime'] ?? '09:00 AM',
      endTime: map['endTime'],
      syllabus: map['syllabus'] ?? '',
      preparationProgress: (map['preparationProgress'] ?? 0.0).toDouble(),
      notes: map['notes'],
      reminderTime: map['reminderTime'],
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
      syllabusTopics: List<String>.from(map['syllabusTopics'] ?? []),
      preparationStartDate: map['preparationStartDate'] != null
          ? DateTime.parse(map['preparationStartDate'])
          : null,
      revisionDeadline: map['revisionDeadline'] != null
          ? DateTime.parse(map['revisionDeadline'])
          : null,
      priority: map['priority'],
      confidence: map['confidence'],
      plannedStudyHours: (map['plannedStudyHours'] as num?)?.toDouble(),
      completedStudyHours: (map['completedStudyHours'] as num?)?.toDouble(),
      practiceTestCount: map['practiceTestCount'],
    );
  }
}

class RevisionTopic {
  final String id;
  final String examId;
  final String title;
  final bool isCompleted;
  final DateTime? plannedDate;
  final int? durationMinutes;
  final int createdAt;
  final int updatedAt;

  RevisionTopic({
    required this.id,
    required this.examId,
    required this.title,
    required this.isCompleted,
    this.plannedDate,
    this.durationMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  RevisionTopic copyWith({
    String? id,
    String? examId,
    String? title,
    bool? isCompleted,
    DateTime? plannedDate,
    int? durationMinutes,
    int? createdAt,
    int? updatedAt,
  }) {
    return RevisionTopic(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      plannedDate: plannedDate ?? this.plannedDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'title': title,
      'isCompleted': isCompleted,
      'plannedDate': plannedDate?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory RevisionTopic.fromMap(Map<String, dynamic> map) {
    return RevisionTopic(
      id: map['id'] ?? '',
      examId: map['examId'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      plannedDate: map['plannedDate'] != null
          ? DateTime.parse(map['plannedDate'])
          : null,
      durationMinutes: map['durationMinutes'],
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}

class Note {
  final String id;
  final String userId;
  final String semesterId;
  final String title;
  final String content;
  final String? subjectId;
  final List<String> tags;
  final bool isFavorite;
  final List<String> localAttachmentPaths;
  final int createdAt;
  final int updatedAt;

  Note({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.title,
    required this.content,
    this.subjectId,
    required this.tags,
    required this.isFavorite,
    required this.localAttachmentPaths,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? title,
    String? content,
    String? subjectId,
    List<String>? tags,
    bool? isFavorite,
    List<String>? localAttachmentPaths,
    int? createdAt,
    int? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      content: content ?? this.content,
      subjectId: subjectId ?? this.subjectId,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      localAttachmentPaths: localAttachmentPaths ?? this.localAttachmentPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'title': title,
      'content': content,
      'subjectId': subjectId,
      'tags': tags,
      'isFavorite': isFavorite,
      'localAttachmentPaths': localAttachmentPaths,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      subjectId: map['subjectId'],
      tags: List<String>.from(map['tags'] ?? []),
      isFavorite: map['isFavorite'] ?? false,
      localAttachmentPaths: List<String>.from(
        map['localAttachmentPaths'] ?? [],
      ),
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}

class StudySession {
  final String id;
  final String userId;
  final String semesterId;
  final String? subjectId;
  final String? examId;
  final String? assignmentId;
  final String title;
  final DateTime plannedDate;
  final String startTime;
  final int durationMinutes;
  final String goal;
  final String status; // Planned, In progress, Completed, Skipped
  final int actualDuration;
  final int createdAt;
  final int updatedAt;
  final int? completedAt;

  StudySession({
    required this.id,
    required this.userId,
    required this.semesterId,
    this.subjectId,
    this.examId,
    this.assignmentId,
    required this.title,
    required this.plannedDate,
    required this.startTime,
    required this.durationMinutes,
    required this.goal,
    required this.status,
    required this.actualDuration,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  StudySession copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? subjectId,
    String? examId,
    String? assignmentId,
    String? title,
    DateTime? plannedDate,
    String? startTime,
    int? durationMinutes,
    String? goal,
    String? status,
    int? actualDuration,
    int? createdAt,
    int? updatedAt,
    int? completedAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      examId: examId ?? this.examId,
      assignmentId: assignmentId ?? this.assignmentId,
      title: title ?? this.title,
      plannedDate: plannedDate ?? this.plannedDate,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      goal: goal ?? this.goal,
      status: status ?? this.status,
      actualDuration: actualDuration ?? this.actualDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'examId': examId,
      'assignmentId': assignmentId,
      'title': title,
      'plannedDate': plannedDate.toIso8601String(),
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'goal': goal,
      'status': status,
      'actualDuration': actualDuration,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'],
      examId: map['examId'],
      assignmentId: map['assignmentId'],
      title: map['title'] ?? '',
      plannedDate: DateTime.parse(
        map['plannedDate'] ?? DateTime.now().toIso8601String(),
      ),
      startTime: map['startTime'] ?? '06:00 PM',
      durationMinutes: map['durationMinutes'] ?? 45,
      goal: map['goal'] ?? '',
      status: map['status'] ?? 'Planned',
      actualDuration: map['actualDuration'] ?? 0,
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
      completedAt: map['completedAt'],
    );
  }
}

class CourseGrade {
  final String id;
  final String semesterId;
  final String subjectName;
  final int credits;
  final String grade; // e.g. A, B, O
  final double gradePoints;

  CourseGrade({
    required this.id,
    required this.semesterId,
    required this.subjectName,
    required this.credits,
    required this.grade,
    required this.gradePoints,
  });

  CourseGrade copyWith({
    String? id,
    String? semesterId,
    String? subjectName,
    int? credits,
    String? grade,
    double? gradePoints,
  }) {
    return CourseGrade(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      subjectName: subjectName ?? this.subjectName,
      credits: credits ?? this.credits,
      grade: grade ?? this.grade,
      gradePoints: gradePoints ?? this.gradePoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semesterId': semesterId,
      'subjectName': subjectName,
      'credits': credits,
      'grade': grade,
      'gradePoints': gradePoints,
    };
  }

  factory CourseGrade.fromMap(Map<String, dynamic> map) {
    return CourseGrade(
      id: map['id'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      credits: map['credits'] ?? 3,
      grade: map['grade'] ?? 'A',
      gradePoints: (map['gradePoints'] ?? 9.0).toDouble(),
    );
  }
}

class AcademicHoliday {
  final String id;
  final String semesterId;
  final String title;
  final String description;
  final DateTime date;
  final String eventType; // holiday, compensatory_saturday
  final String?
  sourceWeekday; // used for compensatory Sat overrides e.g. 'Monday'

  AcademicHoliday({
    required this.id,
    required this.semesterId,
    required this.title,
    required this.description,
    required this.date,
    required this.eventType,
    this.sourceWeekday,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semesterId': semesterId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'eventType': eventType,
      'sourceWeekday': sourceWeekday,
    };
  }

  factory AcademicHoliday.fromMap(Map<String, dynamic> map) {
    return AcademicHoliday(
      id: map['id'] ?? '',
      semesterId: map['semesterId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      eventType: map['eventType'] ?? 'holiday',
      sourceWeekday: map['sourceWeekday'],
    );
  }
}
