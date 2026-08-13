import 'package:flutter/material.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
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

      // Extract details from mock raw payload
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
        setState(() {
          _isValidating = false;
          _validatedSession = {
            'subject': 'Cryptography & Network Security',
            'session': 'SEC-402',
            'instructor': 'Dr. Alan Turing',
            'expiresAt': DateTime.now()
                .add(const Duration(seconds: 45))
                .toIso8601String(),
          };
        });
      }
    });
  }

  void _confirmAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance recorded successfully based on verified QR!'),
      ),
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
