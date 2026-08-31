import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:trackx/core/models/user_role.dart';
import 'package:trackx/features/admin/domain/models/admin_models.dart';

class AdminRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String? get currentAdminUid => _auth.currentUser?.uid;
  String? get currentAdminEmail => _auth.currentUser?.email;

  /// Check if the currently authenticated user is an authorized admin.
  ///
  /// Authorization is based on Firebase Custom Claims — the authoritative source.
  /// The claim `{ "role": "admin" }` is checked first (primary mechanism).
  /// Legacy `isAdmin == true` claim and Firestore `admins/{uid}` are kept as
  /// fallbacks during the transition period.
  Future<bool> verifyAdminStatus([String? uid]) async {
    final targetUid = uid ?? _auth.currentUser?.uid;
    if (targetUid == null || targetUid.isEmpty) return false;

    try {
      // Primary: Check Firebase Custom Claim { "role": "admin" }
      final idTokenResult = await _auth.currentUser?.getIdTokenResult(true);
      final roleClaim = idTokenResult?.claims?['role'];
      if (parseUserRole(roleClaim) == UserRole.admin) {
        return true;
      }

      // Legacy fallback: old isAdmin boolean claim (transition period only)
      if (idTokenResult?.claims?['isAdmin'] == true) {
        return true;
      }

      // Secondary fallback: Firestore admins/{uid} document (transition period only)
      final adminDoc = await _firestore.collection('admins').doc(targetUid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data();
        if (data == null || data['isActive'] == null || data['isActive'] == true) {
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Forces a Firebase ID Token refresh so a newly assigned Custom Claim
  /// becomes visible without the user signing out.
  Future<UserRole> refreshUserClaims() async {
    try {
      await _auth.currentUser?.getIdToken(true);
      final idTokenResult = await _auth.currentUser?.getIdTokenResult();
      return parseUserRole(idTokenResult?.claims?['role']);
    } catch (_) {
      return UserRole.student;
    }
  }

  /// Authenticate admin credentials and verify administrative permissions
  Future<AdminUserSummary> adminLogin(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception('Authentication failed: No user found.');
      }

      // Strict admin verification check
      final isAdmin = await verifyAdminStatus(user.uid);
      if (!isAdmin) {
        // Automatically revoke session for unauthorized logins
        await _auth.signOut();
        throw Exception(
          'Access denied: User "${user.email}" does not have administrator privileges.',
        );
      }

      return AdminUserSummary(
        uid: user.uid,
        name: user.displayName ?? 'Administrator',
        email: user.email ?? email,
        branch: 'Administration',
        semester: 0,
        createdTimestamp: user.metadata.creationTime?.millisecondsSinceEpoch ?? 0,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Admin authentication error: $e');
    }
  }

  /// Sign out administrator
  Future<void> adminLogout() async {
    await _auth.signOut();
  }

  /// Fetch list of all registered users
  Future<List<AdminUserSummary>> fetchAllUsers() async {
    try {
      final snap = await _firestore.collection('users').get();
      final users = <AdminUserSummary>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        data['uid'] = doc.id;
        data['id'] = doc.id;
        users.add(AdminUserSummary.fromMap(data));
      }

      // Sort by creation date descending
      users.sort((a, b) => b.createdTimestamp.compareTo(a.createdTimestamp));
      return users;
    } catch (e) {
      return [];
    }
  }

  /// Fetch single user detailed metrics and subcollection statistics
  Future<AdminUserDetail?> fetchUserDetail(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data() ?? {};
      data['uid'] = userDoc.id;
      final summary = AdminUserSummary.fromMap(data);

      int attendanceCount = 0;
      int subjectsCount = 0;
      int tasksCount = 0;
      int examsCount = 0;
      int notesCount = 0;
      int flashcardDecksCount = 0;

      try {
        final attSnap = await _firestore.collection('users').doc(uid).collection('attendances').get();
        attendanceCount = attSnap.size;
      } catch (_) {}

      try {
        final subSnap = await _firestore.collection('users').doc(uid).collection('subjects').get();
        subjectsCount = subSnap.size;
      } catch (_) {}

      List<AdminUserTask> userTasks = [];
      try {
        final taskSnap = await _firestore.collection('users').doc(uid).collection('tasks').get();
        tasksCount = taskSnap.size;
        userTasks = taskSnap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return AdminUserTask.fromMap(data);
        }).toList();
        userTasks.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return a.dueDate.compareTo(b.dueDate);
        });
      } catch (_) {}

      try {
        final examSnap = await _firestore.collection('users').doc(uid).collection('exams').get();
        examsCount = examSnap.size;
      } catch (_) {}

      try {
        final notesSnap = await _firestore.collection('users').doc(uid).collection('notes').get();
        notesCount = notesSnap.size;
      } catch (_) {}

      try {
        final deckSnap = await _firestore.collection('users').doc(uid).collection('flashcards').get();
        flashcardDecksCount = deckSnap.size;
      } catch (_) {}

      // Fetch user's recent activity logs
      List<ActivityLogEntry> logs = [];
      try {
        final logsSnap = await _firestore
            .collection('activity_logs')
            .where('uid', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();

        logs = logsSnap.docs
            .map((d) => ActivityLogEntry.fromMap(d.data()))
            .toList();
      } catch (_) {}

      final aiBreakdown = <String, int>{
        'Timetable Grid OCR': 0,
        'Exam Datesheet OCR': 0,
        'Attendance Screenshot OCR': 0,
        'Document Analyzer': 0,
        'AI Flashcard Generator': 0,
        'Academic Assistant Chat': 0,
      };

      for (final log in logs) {
        final feat = log.parameters['feature']?.toString().toLowerCase() ?? '';
        final ev = log.event.toLowerCase();
        if (feat.contains('timetable_grid') || ev.contains('timetable_ocr')) {
          aiBreakdown['Timetable Grid OCR'] = (aiBreakdown['Timetable Grid OCR'] ?? 0) + 1;
        } else if (feat.contains('exam_datesheet') || ev.contains('exam_ocr')) {
          aiBreakdown['Exam Datesheet OCR'] = (aiBreakdown['Exam Datesheet OCR'] ?? 0) + 1;
        } else if (feat.contains('attendance_screenshot') || ev.contains('attendance_ocr')) {
          aiBreakdown['Attendance Screenshot OCR'] = (aiBreakdown['Attendance Screenshot OCR'] ?? 0) + 1;
        } else if (feat.contains('document_analyzer') || ev.contains('document_analyzer')) {
          aiBreakdown['Document Analyzer'] = (aiBreakdown['Document Analyzer'] ?? 0) + 1;
        } else if (feat.contains('flashcard') || ev.contains('flashcard')) {
          aiBreakdown['AI Flashcard Generator'] = (aiBreakdown['AI Flashcard Generator'] ?? 0) + 1;
        } else if (feat.contains('assistant_chat') || ev == 'ai_query_sent' || ev.contains('assistant')) {
          aiBreakdown['Academic Assistant Chat'] = (aiBreakdown['Academic Assistant Chat'] ?? 0) + 1;
        }
      }

      final aiQueries = logs.where((l) => l.event == 'ai_query_sent' || l.event.contains('ai')).length;
      final ocrScans = logs.where((l) => l.event == 'ocr_scan_performed' || l.event.contains('ocr') || l.event.contains('timetable_imported')).length;

      return AdminUserDetail(
        summary: summary,
        attendanceCount: attendanceCount,
        subjectsCount: subjectsCount,
        tasksCount: tasksCount,
        examsCount: examsCount,
        notesCount: notesCount,
        flashcardDecksCount: flashcardDecksCount,
        aiQueriesCount: aiQueries,
        ocrScansCount: ocrScans,
        aiFeatureBreakdown: aiBreakdown,
        tasks: userTasks,
        recentLogs: logs,
      );
    } catch (_) {
      return null;
    }
  }

  /// Suspend or reactivate a student user account
  Future<void> toggleUserSuspension(String uid, bool suspend) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'isSuspended': suspend,
        'suspendedTimestamp': suspend ? DateTime.now().millisecondsSinceEpoch : null,
        'updatedTimestamp': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update suspension status: $e');
    }
  }

  /// Fetch aggregate metrics and feature analytics
  Future<AdminAnalyticsOverview> fetchAnalyticsOverview() async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      final totalUsers = usersSnap.size;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final dayMs = 24 * 60 * 60 * 1000;
      final weekMs = 7 * dayMs;

      int activeToday = 0;
      int activeThisWeek = 0;
      int suspendedCount = 0;

      for (final doc in usersSnap.docs) {
        final d = doc.data();
        if (d['isSuspended'] == true) {
          suspendedCount++;
        }
        final lastActive = d['lastActiveTimestamp'] as int? ?? d['updatedTimestamp'] as int? ?? 0;
        if (nowMs - lastActive <= dayMs) {
          activeToday++;
        }
        if (nowMs - lastActive <= weekMs) {
          activeThisWeek++;
        }
      }

      // Query activity logs for feature usage overview
      final logsSnap = await _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      final featureBreakdown = <String, int>{
        'Attendance': 0,
        'Planner & Tasks': 0,
        'AI Assistant': 0,
        'OCR & Timetable Import': 0,
        'Flashcards & Notes': 0,
      };

      int aiQueries = 0;
      int ocrScans = 0;
      int attLogs = 0;

      for (final doc in logsSnap.docs) {
        final ev = (doc.data()['event'] as String? ?? '').toLowerCase();
        if (ev.contains('attendance')) {
          attLogs++;
          featureBreakdown['Attendance'] = (featureBreakdown['Attendance'] ?? 0) + 1;
        } else if (ev.contains('ai')) {
          aiQueries++;
          featureBreakdown['AI Assistant'] = (featureBreakdown['AI Assistant'] ?? 0) + 1;
        } else if (ev.contains('ocr') || ev.contains('import')) {
          ocrScans++;
          featureBreakdown['OCR & Timetable Import'] = (featureBreakdown['OCR & Timetable Import'] ?? 0) + 1;
        } else if (ev.contains('task') || ev.contains('planner') || ev.contains('exam')) {
          featureBreakdown['Planner & Tasks'] = (featureBreakdown['Planner & Tasks'] ?? 0) + 1;
        } else if (ev.contains('note') || ev.contains('flashcard')) {
          featureBreakdown['Flashcards & Notes'] = (featureBreakdown['Flashcards & Notes'] ?? 0) + 1;
        }
      }

      return AdminAnalyticsOverview(
        totalUsers: totalUsers,
        activeUsersToday: activeToday,
        activeUsersThisWeek: activeThisWeek,
        suspendedUsersCount: suspendedCount,
        totalAiQueries: aiQueries,
        totalOcrScans: ocrScans,
        totalAttendanceLogs: attLogs,
        featureUsageBreakdown: featureBreakdown,
      );
    } catch (_) {
      return AdminAnalyticsOverview.empty();
    }
  }

  /// Fetch recent real-time system activity logs
  Future<List<ActivityLogEntry>> fetchRecentActivityLogs({int limit = 50}) async {
    try {
      final snap = await _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((d) => ActivityLogEntry.fromMap(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
