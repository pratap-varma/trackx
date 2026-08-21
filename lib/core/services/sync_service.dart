import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/core/models/sync_operation_model.dart';
import 'package:trackx/core/services/hive_db_service.dart';

class SyncService {
  final HiveDbService _db;
  final Connectivity _connectivity = Connectivity();

  bool _syncing = false;
  String? _activeUserId;

  SyncService(this._db) {
    _connectivity.onConnectivityChanged.listen((event) {
      triggerSync();
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
    final op = SyncOperation(
      id: 'sync-${DateTime.now().millisecondsSinceEpoch}-$entityId',
      userId: uid,
      entityType: entityType,
      entityId: entityId,
      operationType: opType,
      payload: payload,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      retryCount: 0,
      status: 'pending',
      deviceId: 'install-id',
    );

    final box = _db.getBox(HiveDbService.boxSyncQueue);
    await box.put(op.id, op.toMap());

    // Attempt trigger push sync immediately
    triggerSync();
  }

  Future<void> triggerSync() async {
    if (_syncing || _activeUserId == null) return;
    _syncing = true;

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.isEmpty ||
          !connectivityResult.any((r) => r != ConnectivityResult.none)) {
        _syncing = false;
        return;
      }

      await _pushQueue();
      await _pullUpdates();
    } catch (_) {
      // Offline fallback
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pushQueue() async {
    final box = _db.getBox(HiveDbService.boxSyncQueue);
    final ops = box.values
        .map((e) => SyncOperation.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // Sort oldest first
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final op in ops) {
      if (op.status == 'completed') continue;

      try {
        final collectionName = '${op.entityType}s'; // e.g. semesters, tasks
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_activeUserId)
            .collection(collectionName)
            .doc(op.entityId);

        if (op.operationType == 'delete') {
          await docRef.delete();
        } else {
          await docRef.set(op.payload, SetOptions(merge: true));
        }

        // Mark completed and remove from local sync queue box
        await box.delete(op.id);
      } catch (_) {
        // Backoff retry count
        await box.put(
          op.id,
          op
              .copyWith(
                retryCount: op.retryCount + 1,
                lastAttemptAt: DateTime.now().millisecondsSinceEpoch,
                status: 'failed',
              )
              .toMap(),
        );
        break; // Stop execution on connection failure
      }
    }
  }

  Future<void> _pullUpdates() async {
    // Stage 6 Pull sync downloads changed items from Firestore collections
    // This utilizes server-timestamp updates for last-write-wins comparisons
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
      ];

      for (final type in collections) {
        final boxName = _getBoxNameForType(type);
        if (boxName == null) continue;

        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_activeUserId)
            .collection('${type}s')
            .get();

        final localBox = _db.getBox(boxName);

        for (final doc in querySnapshot.docs) {
          final remoteData = doc.data();
          final localData = localBox.get(doc.id);

          if (localData == null) {
            // Write new records directly
            await localBox.put(doc.id, remoteData);
          } else {
            // Conflict resolution: Last Write Wins based on updatedAt
            final remoteUpdated = remoteData['updatedAt'] ?? 0;
            final localUpdated = (localData as Map)['updatedAt'] ?? 0;

            if (remoteUpdated > localUpdated) {
              await localBox.put(doc.id, remoteData);
            }
          }
        }
      }
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
    }[type];
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(hiveDbServiceProvider);
  return SyncService(db);
});

final hiveDbServiceProvider = Provider<HiveDbService>((ref) {
  return HiveDbService();
});
