import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/subjects/domain/subject_model.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/theme/app_theme.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isValidating = false;
  Map<String, dynamic>? _validatedSession;
  String? _error;

  void _simulateScan(String rawPayload) {
    setState(() {
      _isValidating = true;
      _validatedSession = null;
      _error = null;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      // Extract details from raw payload parameters
      if (rawPayload.contains('EXPIRED')) {
        setState(() {
          _isValidating = false;
          _error = 'Payload has expired (exceeded 60s window).';
        });
      } else if (rawPayload.contains('INVALID_SIG')) {
        setState(() {
          _isValidating = false;
          _error = 'Invalid token cryptographic signature.';
        });
      } else {
        final parsedParams = Uri.splitQueryString(rawPayload);
        final subName =
            parsedParams['subject'] ?? parsedParams['sub'] ?? 'Class Session';
        final session =
            parsedParams['session'] ??
            parsedParams['SESSION_ID'] ??
            'Verified QR';
        final instructor =
            parsedParams['instructor'] ?? parsedParams['faculty'] ?? 'Faculty';

        setState(() {
          _isValidating = false;
          _validatedSession = {
            'subject': subName,
            'session': session,
            'instructor': instructor,
            'expiresAt': DateTime.now()
                .add(const Duration(seconds: 45))
                .toIso8601String(),
          };
        });
      }
    });
  }

  Future<void> _confirmAttendance() async {
    final session = _validatedSession;
    if (session == null) return;

    final activeSem = ref.read(activeSemesterProvider);
    final subjects = ref.read(subjectRepositoryProvider);
    final authState = ref.read(authRepositoryProvider);
    final userId = authState.userProfile?.id ?? 'user';
    final targetName = session['subject'].toString().toLowerCase().trim();

    String semesterId = activeSem?.id ?? 'sem_default';
    Subject? matchedSubject = subjects.cast<Subject?>().firstWhere(
      (s) =>
          s != null &&
          (s.name.toLowerCase().trim() == targetName ||
              (s.code != null && s.code!.toLowerCase().trim() == targetName) ||
              s.name.toLowerCase().contains(targetName) ||
              targetName.contains(s.name.toLowerCase())),
      orElse: () => null,
    );

    if (matchedSubject == null && activeSem != null) {
      final added = await ref.read(subjectRepositoryProvider.notifier).addSubject(
            activeSem.id,
            session['subject'].toString(),
            session['instructor'].toString(),
            0xFF5B5FEF,
            75.0,
          );
      if (added) {
        final updatedSubjects = ref.read(subjectRepositoryProvider);
        matchedSubject = updatedSubjects.firstWhere(
          (s) => s.name.toLowerCase() == targetName,
          orElse: () => updatedSubjects.last,
        );
      }
    }

    if (matchedSubject != null) {
      await ref.read(attendanceRepositoryProvider.notifier).markAttendance(
            userId: userId,
            semesterId: semesterId,
            subjectId: matchedSubject.id,
            date: DateTime.now(),
            status: 'present',
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance marked Present for ${matchedSubject?.name ?? session['subject']}!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Scan QR Attendance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Align your camera to scan the dynamic classroom presentation QR. Scanning alone does not automatically mark attendance.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 20),
            GlassContainer(
              child: Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black26,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Simulate Scan Actions:',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _simulateScan(
                          'SESSION_ID=SEC402&SIG=0x932f&EXP=VALID',
                        ),
                        child: const Text('Valid Class'),
                      ),
                      ElevatedButton(
                        onPressed: () => _simulateScan(
                          'SESSION_ID=SEC402&SIG=0x932f&EXP=EXPIRED',
                        ),
                        child: const Text('Expired Code'),
                      ),
                      ElevatedButton(
                        onPressed: () => _simulateScan(
                          'SESSION_ID=SEC402&SIG=INVALID_SIG&EXP=VALID',
                        ),
                        child: const Text('Bad Signature'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isValidating)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPurple),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (_validatedSession != null) ...[
              const Text(
                'Suggested Class Found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _validatedSession!['subject'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Session: ${_validatedSession!['session']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Instructor: ${_validatedSession!['instructor']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassPrimaryButton(
                      text: 'Confirm Attendance',
                      onPressed: _confirmAttendance,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
