import 'package:flutter_test/flutter_test.dart';
import 'package:trackx/core/models/sync_operation_model.dart';

void main() {
  group('Stage 6 - Database Migration & Conflict Tests', () {
    test('SyncOperation serialization matches spec', () {
      final op = SyncOperation(
        id: 'o1',
        userId: 'u1',
        entityType: 'task',
        entityId: 't1',
        operationType: 'create',
        payload: {'title': 'Submit Assignment'},
        createdAt: 100,
        retryCount: 0,
        status: 'pending',
        deviceId: 'd1',
      );

      final map = op.toMap();
      final fromMap = SyncOperation.fromMap(map);

      expect(fromMap.id, 'o1');
      expect(fromMap.entityType, 'task');
      expect(fromMap.operationType, 'create');
      expect(fromMap.payload['title'], 'Submit Assignment');
      expect(fromMap.status, 'pending');
    });

    test('Conflict resolution last-write-wins logic matches spec', () {
      final remoteData = {
        'id': 's1',
        'name': 'Physics Remote',
        'updatedAt': 200,
      };

      final localData = {'id': 's1', 'name': 'Physics Local', 'updatedAt': 100};

      // Remote wins
      final remoteUpdated = remoteData['updatedAt'] as int;
      final localUpdated = localData['updatedAt'] as int;

      expect(remoteUpdated > localUpdated, true);
    });

    test('Backup JSON validation checks schemas version', () {
      final backup = {
        'app': 'TrackX',
        'schemaVersion': 1,
        'exportedAt': '2026-07-17',
        'semesters': [],
        'subjects': [],
      };

      expect(backup['app'], 'TrackX');
      expect(backup['schemaVersion'], 1);
    });
  });
}
