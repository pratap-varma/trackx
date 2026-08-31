import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/core/models/sync_operation_model.dart';
import 'package:trackx/core/services/hive_db_service.dart';
import 'package:trackx/features/attendance/data/attendance_repository.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/subjects/data/subject_repository.dart';
import 'package:trackx/features/timetable/data/repositories/timetable_repository.dart';

class SyncStatusState {
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncTime;
  final String? lastError;

  const SyncStatusState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncTime,
    this.lastError,
  });

  SyncStatusState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncTime,
    String? lastError,
  }) {
    return SyncStatusState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  SyncStatusNotifier() : super(const SyncStatusState());

  void setSyncing(bool isSyncing) {
    state = state.copyWith(isSyncing: isSyncing);
  }

  void updateCounts({required int pending, required int failed}) {
    state = state.copyWith(pendingCount: pending, failedCount: failed);
  }

  void recordSuccess() {
    state = state.copyWith(
      isSyncing: false,
      lastSyncTime: DateTime.now(),
      lastError: null,
    );
  }

  void recordError(String error) {
    state = state.copyWith(isSyncing: false, lastError: error);
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
  return SyncStatusNotifier();
});

class SyncService {
  final HiveDbService _db;
  final Ref? _ref;
  final Connectivity _connectivity = Connectivity();

  bool _syncing = false;
  String? _activeUserId;
  static const int _maxRetries = 5;

  SyncService(this._db, [this._ref]) {
    Future.microtask(() {
      try {
        _connectivity.onConnectivityChanged.listen(
          (_) {
            triggerSync();
          },
          onError: (_) {},
        );
      } catch (_) {}
    });
  }

  void setActiveUser(String? userId) {
    _activeUserId = userId;
    if (userId != null) {
      triggerSync();
    }
  }

  Future<void> addToQueue(
    String entityType,
    String entityId,
    String opType,
    Map<String, dynamic> payload,
  ) async {
    final uid = _activeUserId ?? 'guest';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Ensure payload always includes an updatedAt timestamp for LWW conflict resolution
    final normalizedPayload = Map<String, dynamic>.from(payload);
    normalizedPayload['updatedAt'] ??= nowMs;
    normalizedPayload['updatedTimestamp'] ??= nowMs;

    final op = SyncOperation(
      id: 'sync-$nowMs-$entityId',
      userId: uid,
      entityType: entityType,
      entityId: entityId,
      operationType: opType,
      payload: normalizedPayload,
      createdAt: nowMs,
      retryCount: 0,
      status: 'pending',
      deviceId: 'install-id',
    );

    try {
      final box = _db.getBoxOrNull(HiveDbService.boxSyncQueue);
      if (box != null) {
        await box.put(op.id, op.toMap());
        _updateStatusCounts();
        triggerSync();
      }
    } catch (_) {}
  }

  void _updateStatusCounts() {
    try {
      final box = _db.getBoxOrNull(HiveDbService.boxSyncQueue);
      if (box != null) {
        final ops = box.values
            .map((e) => SyncOperation.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        final pending = ops.where((o) => o.status != 'completed').length;
        final failed = ops.where((o) => o.status == 'failed').length;
        _ref?.read(syncStatusProvider.notifier).updateCounts(
              pending: pending,
              failed: failed,
            );
      }
    } catch (_) {}
  }

  Future<void> triggerSync() async {
    if (_syncing || _activeUserId == null || _activeUserId == 'guest') return;
    _syncing = true;
    _ref?.read(syncStatusProvider.notifier).setSyncing(true);

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.isEmpty ||
          !connectivityResult.any((r) => r != ConnectivityResult.none)) {
        _syncing = false;
        _ref?.read(syncStatusProvider.notifier).setSyncing(false);
        return;
      }

      await _pushQueue();
      await _pullUpdates();
      _ref?.read(syncStatusProvider.notifier).recordSuccess();
    } catch (e) {
      _ref?.read(syncStatusProvider.notifier).recordError(e.toString());
    } finally {
      _syncing = false;
      _updateStatusCounts();
      _ref?.read(syncStatusProvider.notifier).setSyncing(false);
    }
  }

  Future<void> _pushQueue() async {
    final box = _db.getBox(HiveDbService.boxSyncQueue);
    final ops = box.values
        .map((e) => SyncOperation.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // Sort oldest first
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Batch operations where possible to optimize Firestore read/write operations
    final firestore = FirebaseFirestore.instance;

    for (final op in ops) {
      if (op.status == 'completed') {
        await box.delete(op.id);
        continue;
      }

      // Check exponential backoff retry threshold
      if (op.retryCount >= _maxRetries) {
        continue;
      }

      try {
        DocumentReference docRef;
        if (op.entityType == 'profile') {
          docRef = firestore.collection('users').doc(_activeUserId);
        } else {
          final collectionName = '${op.entityType}s'; // e.g. semesters, tasks
          docRef = firestore
              .collection('users')
              .doc(_activeUserId)
              .collection(collectionName)
              .doc(op.entityId);
        }

        if (op.operationType == 'delete') {
          await docRef.delete();
        } else {
          // Push payload with Last-Write-Wins merge
          await docRef.set(op.payload, SetOptions(merge: true));
        }

        // Successfully synchronized: remove from local queue
        await box.delete(op.id);
      } catch (e) {
        // Increment retry count with exponential backoff delay timestamp
        await box.put(
          op.id,
          op
              .copyWith(
                retryCount: op.retryCount + 1,
                lastAttemptAt: DateTime.now().millisecondsSinceEpoch,
                status: 'failed',
                errorMessage: e.toString(),
              )
              .toMap(),
        );
        break; // Stop on network/credential error
      }
    }
  }

  Future<void> _pullUpdates() async {
    try {
      final collections = [
        'semester',
        'subject',
        'attendance',
        'timetable',
        'task',
        'note',
        'cgpaCourse',
        'programme',
        'dependency',
        'scenario',
        'course',
        'topic',
        'resource',
        'flashcardDeck',
      ];

      final firestore = FirebaseFirestore.instance;

      for (final type in collections) {
        final boxName = _getBoxNameForType(type);
        if (boxName == null) continue;

        final querySnapshot = await firestore
            .collection('users')
            .doc(_activeUserId)
            .collection('${type}s')
            .get();

        final localBox = _db.getBox(boxName);

        for (final doc in querySnapshot.docs) {
          final remoteData = Map<String, dynamic>.from(doc.data());
          final localData = localBox.get(doc.id);

          if (localData == null) {
            // New remote record: store locally
            await localBox.put(doc.id, remoteData);
          } else {
            // Explicit Last-Write-Wins (LWW) Conflict Resolution with field-level merge
            final localMap = Map<String, dynamic>.from(localData as Map);
            final remoteUpdated = (remoteData['updatedAt'] ??
                remoteData['updatedTimestamp'] ??
                0) as num;
            final localUpdated = (localMap['updatedAt'] ??
                localMap['updatedTimestamp'] ??
                0) as num;

            if (remoteUpdated >= localUpdated) {
              // Remote is newer or equal: apply remote fields over local
              final merged = Map<String, dynamic>.from(localMap)
                ..addAll(remoteData);
              await localBox.put(doc.id, merged);
            }
          }
        }
      }

      // Re-hydrate active in-memory repositories with downloaded cloud records
      try {
        _ref?.read(semesterRepositoryProvider.notifier).reloadFromStorage();
        _ref?.read(subjectRepositoryProvider.notifier).reloadFromStorage();
        _ref?.read(attendanceRepositoryProvider.notifier).reloadFromStorage();
        _ref?.read(timetableRepositoryProvider.notifier).reloadFromStorage();
      } catch (_) {}
    } catch (_) {}
  }

  String? _getBoxNameForType(String type) {
    return {
      'semester': HiveDbService.boxSemesters,
      'subject': HiveDbService.boxSubjects,
      'attendance': HiveDbService.boxAttendance,
      'timetable': HiveDbService.boxTimetable,
      'task': HiveDbService.boxTasks,
      'note': HiveDbService.boxNotes,
      'cgpaCourse': HiveDbService.boxCgpa,
      'programme': HiveDbService.boxProgrammes,
      'dependency': HiveDbService.boxDependencies,
      'scenario': HiveDbService.boxScenarios,
      'course': HiveDbService.boxCourses,
      'topic': HiveDbService.boxTopics,
      'resource': HiveDbService.boxResources,
      'flashcardDeck': HiveDbService.boxFlashcards,
    }[type];
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(hiveDbServiceProvider);
  return SyncService(db, ref);
});

final hiveDbServiceProvider = Provider<HiveDbService>((ref) {
  return HiveDbService();
});
