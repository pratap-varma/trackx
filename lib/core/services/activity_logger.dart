import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityLogger {
  FirebaseFirestore? _firestore;
  fb.FirebaseAuth? _firebaseAuth;

  ActivityLogger() {
    try {
      _firestore = FirebaseFirestore.instance;
      _firebaseAuth = fb.FirebaseAuth.instance;
    } catch (_) {}
  }

  Future<void> logEvent(
    String eventName, {
    String? userId,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final uid = userId ?? _firebaseAuth?.currentUser?.uid ?? 'guest';
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final logId = 'log-$nowMs-${DateTime.now().microsecond}';

      final data = {
        'id': logId,
        'uid': uid,
        'event': eventName,
        'timestamp': nowMs,
        'parameters': parameters ?? {},
      };

      if (_firestore != null && uid != 'guest') {
        // Fire-and-forget log write to activity_logs collection
        _firestore!
            .collection('activity_logs')
            .doc(logId)
            .set(data)
            .catchError((_) {});

        // Touch lastActiveTimestamp on the user profile
        _firestore!
            .collection('users')
            .doc(uid)
            .set({
              'lastActiveTimestamp': nowMs,
              'updatedTimestamp': nowMs,
            }, SetOptions(merge: true))
            .catchError((_) {});
      }
    } catch (_) {}
  }
}

final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  return ActivityLogger();
});
