class TimetableEntry {
  final String id;
  final String userId;
  final String semesterId;
  final String subjectId;
  final int dayOfWeek; // 1 = Monday, 6 = Saturday
  final int periodNumber; // 1 to 6
  final int startTime; // Minutes from midnight (e.g. 555 for 9:15 AM)
  final int endTime; // Minutes from midnight (e.g. 615 for 10:15 AM)
  final String? room;
  final String? notes;
  final bool isEnabled;
  final int createdAt;
  final int updatedAt;

  TimetableEntry({
    required this.id,
    required this.userId,
    required this.semesterId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    this.room,
    this.notes,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isValidRange => startTime < endTime;

  String formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours);
    final displayMin = mins < 10 ? '0$mins' : '$mins';
    return '$displayHour:$displayMin $period';
  }

  String get startTimeDisplay => formatTime(startTime);
  String get endTimeDisplay => formatTime(endTime);

  DateTime toDateTime(DateTime referenceDate, int minutes) {
    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  bool isCurrent(DateTime currentTime) {
    if (!isEnabled) return false;
    // Verify if dayOfWeek matches
    if (currentTime.weekday != dayOfWeek) return false;

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    return currentMinutes >= startTime && currentMinutes < endTime;
  }

  bool isCompleted(DateTime currentTime) {
    if (!isEnabled) return false;
    if (currentTime.weekday != dayOfWeek)
      return currentTime.weekday > dayOfWeek;

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    return currentMinutes >= endTime;
  }

  TimetableEntry copyWith({
    String? id,
    String? userId,
    String? semesterId,
    String? subjectId,
    int? dayOfWeek,
    int? periodNumber,
    int? startTime,
    int? endTime,
    String? room,
    String? notes,
    bool? isEnabled,
    int? createdAt,
    int? updatedAt,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      periodNumber: periodNumber ?? this.periodNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      notes: notes ?? this.notes,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'dayOfWeek': dayOfWeek,
      'periodNumber': periodNumber,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'notes': notes,
      'isEnabled': isEnabled,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? 1,
      periodNumber: map['periodNumber'] ?? 1,
      startTime: map['startTime'] ?? 555,
      endTime: map['endTime'] ?? 615,
      room: map['room'],
      notes: map['notes'],
      isEnabled: map['isEnabled'] ?? true,
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}
