abstract class AttendanceInputSource {
  String get sourceName;
}

class QrAttendanceSource implements AttendanceInputSource {
  @override
  String get sourceName => 'QR';
}

class NfcAttendanceSource implements AttendanceInputSource {
  @override
  String get sourceName => 'NFC';
}

class VoiceAttendanceSource implements AttendanceInputSource {
  @override
  String get sourceName => 'Voice';
}

class AttendanceSuggestion {
  final String subjectId;
  final DateTime suggestedAt;
  final AttendanceInputSource suggestionSource;

  AttendanceSuggestion({
    required this.subjectId,
    required this.suggestedAt,
    required this.suggestionSource,
  });
}

class AttendanceVerificationResult {
  final bool isVerified;
  final String? rejectionReason;

  AttendanceVerificationResult({
    required this.isVerified,
    this.rejectionReason,
  });
}
