class UserProfile {
  final String id;
  final String name;
  final String email;
  final String branch;
  final int semester;
  final double globalTarget;
  final String themeMode; // 'dark', 'light', 'system'
  final String themeColorPack; // 'purple', 'blue', etc.
  final bool onboardingCompleted;
  final int createdTimestamp;
  final int updatedTimestamp;

  // Stage 16 fields
  final String? collegeName;
  final String? registrationNumber;
  final String? programmeName;
  final int? joiningYear;
  final int? expectedGraduationYear;
  final String? currentSemesterId;
  final double defaultAttendanceTarget;
  final String preferredLanguage;
  final String preferredTimezone;
  final int preferredStudySessionMinutes;
  final bool cloudSyncEnabled;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.branch,
    required this.semester,
    required this.globalTarget,
    required this.themeMode,
    required this.themeColorPack,
    required this.onboardingCompleted,
    required this.createdTimestamp,
    required this.updatedTimestamp,
    this.collegeName,
    this.registrationNumber,
    this.programmeName,
    this.joiningYear,
    this.expectedGraduationYear,
    this.currentSemesterId,
    double? defaultAttendanceTarget,
    String? preferredLanguage,
    String? preferredTimezone,
    int? preferredStudySessionMinutes,
    bool? cloudSyncEnabled,
  })  : defaultAttendanceTarget = defaultAttendanceTarget ?? globalTarget,
        preferredLanguage = preferredLanguage ?? 'en',
        preferredTimezone = preferredTimezone ?? 'UTC',
        preferredStudySessionMinutes = preferredStudySessionMinutes ?? 25,
        cloudSyncEnabled = cloudSyncEnabled ?? true;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? branch,
    int? semester,
    double? globalTarget,
    String? themeMode,
    String? themeColorPack,
    bool? onboardingCompleted,
    int? createdTimestamp,
    int? updatedTimestamp,
    String? collegeName,
    String? registrationNumber,
    String? programmeName,
    int? joiningYear,
    int? expectedGraduationYear,
    String? currentSemesterId,
    double? defaultAttendanceTarget,
    String? preferredLanguage,
    String? preferredTimezone,
    int? preferredStudySessionMinutes,
    bool? cloudSyncEnabled,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      branch: branch ?? this.branch,
      semester: semester ?? this.semester,
      globalTarget: globalTarget ?? this.globalTarget,
      themeMode: themeMode ?? this.themeMode,
      themeColorPack: themeColorPack ?? this.themeColorPack,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
      updatedTimestamp: updatedTimestamp ?? this.updatedTimestamp,
      collegeName: collegeName ?? this.collegeName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      programmeName: programmeName ?? this.programmeName,
      joiningYear: joiningYear ?? this.joiningYear,
      expectedGraduationYear: expectedGraduationYear ?? this.expectedGraduationYear,
      currentSemesterId: currentSemesterId ?? this.currentSemesterId,
      defaultAttendanceTarget: defaultAttendanceTarget ?? this.defaultAttendanceTarget,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredTimezone: preferredTimezone ?? this.preferredTimezone,
      preferredStudySessionMinutes: preferredStudySessionMinutes ?? this.preferredStudySessionMinutes,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'branch': branch,
      'semester': semester,
      'globalTarget': globalTarget,
      'themeMode': themeMode,
      'themeColorPack': themeColorPack,
      'onboardingCompleted': onboardingCompleted,
      'createdTimestamp': createdTimestamp,
      'updatedTimestamp': updatedTimestamp,
      'collegeName': collegeName,
      'registrationNumber': registrationNumber,
      'programmeName': programmeName,
      'joiningYear': joiningYear,
      'expectedGraduationYear': expectedGraduationYear,
      'currentSemesterId': currentSemesterId,
      'defaultAttendanceTarget': defaultAttendanceTarget,
      'preferredLanguage': preferredLanguage,
      'preferredTimezone': preferredTimezone,
      'preferredStudySessionMinutes': preferredStudySessionMinutes,
      'cloudSyncEnabled': cloudSyncEnabled,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final double globalTargetVal = (map['globalTarget'] as num?)?.toDouble() ?? 75.0;
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      branch: map['branch'] ?? '',
      semester: map['semester'] ?? 1,
      globalTarget: globalTargetVal,
      themeMode: map['themeMode'] ?? 'dark',
      themeColorPack: map['themeColorPack'] ?? 'purple',
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      createdTimestamp: map['createdTimestamp'] ?? 0,
      updatedTimestamp: map['updatedTimestamp'] ?? 0,
      collegeName: map['collegeName'],
      registrationNumber: map['registrationNumber'],
      programmeName: map['programmeName'],
      joiningYear: map['joiningYear'],
      expectedGraduationYear: map['expectedGraduationYear'],
      currentSemesterId: map['currentSemesterId'],
      defaultAttendanceTarget: (map['defaultAttendanceTarget'] as num?)?.toDouble() ?? globalTargetVal,
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      preferredTimezone: map['preferredTimezone'] ?? 'UTC',
      preferredStudySessionMinutes: map['preferredStudySessionMinutes'],
      cloudSyncEnabled: map['cloudSyncEnabled'],
    );
  }
}
