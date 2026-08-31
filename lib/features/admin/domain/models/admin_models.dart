class AdminUserSummary {
  final String uid;
  final String name;
  final String email;
  final String branch;
  final int semester;
  final int createdTimestamp;
  final int? lastActiveTimestamp;
  final bool isSuspended;
  final int totalSubjects;
  final int totalAttendanceRecords;
  final int totalTasks;

  AdminUserSummary({
    required this.uid,
    required this.name,
    required this.email,
    required this.branch,
    required this.semester,
    required this.createdTimestamp,
    this.lastActiveTimestamp,
    this.isSuspended = false,
    this.totalSubjects = 0,
    this.totalAttendanceRecords = 0,
    this.totalTasks = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'branch': branch,
      'semester': semester,
      'createdTimestamp': createdTimestamp,
      'lastActiveTimestamp': lastActiveTimestamp,
      'isSuspended': isSuspended,
      'totalSubjects': totalSubjects,
      'totalAttendanceRecords': totalAttendanceRecords,
      'totalTasks': totalTasks,
    };
  }

  factory AdminUserSummary.fromMap(Map<String, dynamic> map) {
    return AdminUserSummary(
      uid: map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      branch: map['department'] ?? map['branch'] ?? '',
      semester: map['semester'] ?? 1,
      createdTimestamp: map['createdTimestamp'] ?? (map['createdAt'] is int ? map['createdAt'] : 0),
      lastActiveTimestamp: map['lastActiveTimestamp'],
      isSuspended: map['isSuspended'] ?? false,
      totalSubjects: map['totalSubjects'] ?? 0,
      totalAttendanceRecords: map['totalAttendanceRecords'] ?? 0,
      totalTasks: map['totalTasks'] ?? 0,
    );
  }

  AdminUserSummary copyWith({
    String? uid,
    String? name,
    String? email,
    String? branch,
    int? semester,
    int? createdTimestamp,
    int? lastActiveTimestamp,
    bool? isSuspended,
    int? totalSubjects,
    int? totalAttendanceRecords,
    int? totalTasks,
  }) {
    return AdminUserSummary(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      branch: branch ?? this.branch,
      semester: semester ?? this.semester,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
      lastActiveTimestamp: lastActiveTimestamp ?? this.lastActiveTimestamp,
      isSuspended: isSuspended ?? this.isSuspended,
      totalSubjects: totalSubjects ?? this.totalSubjects,
      totalAttendanceRecords: totalAttendanceRecords ?? this.totalAttendanceRecords,
      totalTasks: totalTasks ?? this.totalTasks,
    );
  }
}

class AdminUserTask {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final DateTime dueDate;
  final bool isCompleted;
  final int? completedAt;
  final int createdAt;

  AdminUserTask({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'createdAt': createdAt,
    };
  }

  factory AdminUserTask.fromMap(Map<String, dynamic> map) {
    return AdminUserTask(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Task',
      description: map['description'],
      category: map['category'] ?? 'Task',
      priority: map['priority'] ?? 'Medium',
      dueDate: map['dueDate'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : (map['dueDate'] is String
              ? DateTime.tryParse(map['dueDate']) ?? DateTime.now()
              : DateTime.now()),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] is int ? map['completedAt'] : null,
      createdAt: map['createdAt'] is int ? map['createdAt'] : 0,
    );
  }
}

class ActivityLogEntry {
  final String id;
  final String uid;
  final String event;
  final int timestamp;
  final Map<String, dynamic> parameters;

  ActivityLogEntry({
    required this.id,
    required this.uid,
    required this.event,
    required this.timestamp,
    this.parameters = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'event': event,
      'timestamp': timestamp,
      'parameters': parameters,
    };
  }

  factory ActivityLogEntry.fromMap(Map<String, dynamic> map) {
    return ActivityLogEntry(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      event: map['event'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
    );
  }
}

class AdminUserDetail {
  final AdminUserSummary summary;
  final int attendanceCount;
  final int subjectsCount;
  final int tasksCount;
  final int examsCount;
  final int notesCount;
  final int flashcardDecksCount;
  final int aiQueriesCount;
  final int ocrScansCount;
  final Map<String, int> aiFeatureBreakdown;
  final List<AdminUserTask> tasks;
  final List<ActivityLogEntry> recentLogs;

  AdminUserDetail({
    required this.summary,
    this.attendanceCount = 0,
    this.subjectsCount = 0,
    this.tasksCount = 0,
    this.examsCount = 0,
    this.notesCount = 0,
    this.flashcardDecksCount = 0,
    this.aiQueriesCount = 0,
    this.ocrScansCount = 0,
    this.aiFeatureBreakdown = const {},
    this.tasks = const [],
    this.recentLogs = const [],
  });
}

class AdminAnalyticsOverview {
  final int totalUsers;
  final int activeUsersToday;
  final int activeUsersThisWeek;
  final int suspendedUsersCount;
  final int totalAiQueries;
  final int totalOcrScans;
  final int totalAttendanceLogs;
  final Map<String, int> featureUsageBreakdown;

  AdminAnalyticsOverview({
    required this.totalUsers,
    required this.activeUsersToday,
    required this.activeUsersThisWeek,
    required this.suspendedUsersCount,
    required this.totalAiQueries,
    required this.totalOcrScans,
    required this.totalAttendanceLogs,
    required this.featureUsageBreakdown,
  });

  factory AdminAnalyticsOverview.empty() {
    return AdminAnalyticsOverview(
      totalUsers: 0,
      activeUsersToday: 0,
      activeUsersThisWeek: 0,
      suspendedUsersCount: 0,
      totalAiQueries: 0,
      totalOcrScans: 0,
      totalAttendanceLogs: 0,
      featureUsageBreakdown: {},
    );
  }
}
